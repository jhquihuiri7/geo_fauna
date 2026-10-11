"""Publica en el Muro avistamientos reales de Galápagos tomados de iNaturalist.

La cola sale de `data/inaturalist_galapagos.csv` (generado con
`backend/tools/fetch_inaturalist.py`). Cada ejecución toma la siguiente fila,
copia la foto a Storage y crea el registro y el post del Muro con la misma forma
que usa la app, firmados por la cuenta oficial y con crédito al observador.
"""

from __future__ import annotations

import csv
import logging
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from firebase_admin import firestore, storage

CSV_PATH = Path(__file__).resolve().parent / "data" / "inaturalist_galapagos.csv"
SOURCE = "inaturalist"
CURSOR_PATH = ("appMeta", "inaturalistSeed")
AUTHOR = {
    "uid": "ecoguia-avistamientos",
    "name": "EcoGuía · Avistamientos",
    "photoUrl": None,
    "userType": "Cuenta oficial",
}
GALAPAGOS_TZ = timezone(timedelta(hours=-6))
USER_AGENT = "GeoFauna/1.0 (seed del Muro)"
# Filas a intentar por ejecución si alguna foto ya no existe en iNaturalist.
MAX_ATTEMPTS = 5


def load_rows(path: Path = CSV_PATH) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as file:
        return list(csv.DictReader(file))


def credit_line(row: dict[str, str]) -> str:
    return f"📷 {row['observer_name']} vía iNaturalist · {row['photo_license']}"


def build_notes(row: dict[str, str]) -> str:
    parts = [row["description"].strip(), credit_line(row), row["observation_url"]]
    return "\n\n".join(part for part in parts if part)


def observed_at(row: dict[str, str]) -> datetime:
    value = row["observed_at"]
    if "T" in value:
        return datetime.fromisoformat(value)
    # Sin hora registrada: mediodía en Galápagos.
    day = datetime.fromisoformat(value)
    return day.replace(hour=12, tzinfo=GALAPAGOS_TZ)


def location_fields(row: dict[str, str]) -> dict[str, Any]:
    latitude = float(row["latitude"])
    longitude = float(row["longitude"])
    title = row["place_label"]
    detail = row["place_detail"]
    return {
        "placeLabel": title,
        "placeName": title,
        "locationLabel": f"{title} - {detail}" if detail else title,
        "location": firestore.GeoPoint(latitude, longitude),
        "latitude": latitude,
        "longitude": longitude,
    }


def build_documents(
    row: dict[str, str],
    record_id: str,
    evidence: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Devuelve (fieldRecord, publicFeed) con la misma forma que crea la app."""
    category = row["category"].lower()
    species = row["species_name"]
    notes = build_notes(row)
    photo_url = evidence["displayUrl"]
    thumb_url = evidence["thumbUrl"]
    source_fields = {
        "source": SOURCE,
        "sourceUrl": row["observation_url"],
        "inaturalistId": int(row["inat_id"]),
        "photoLicense": row["photo_license"],
        "photoAttribution": row["observer_name"],
    }
    shared = {
        "validationSummary": {"confirmations": 0, "disputes": 0},
        "reactionCounts": {},
        "commentCount": 0,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
        **location_fields(row),
        **source_fields,
    }

    record = {
        "authorId": AUTHOR["uid"],
        "authorName": AUTHOR["name"],
        "authorPhotoUrl": AUTHOR["photoUrl"],
        "authorSnapshot": AUTHOR,
        "category": category,
        "categoryLabel": row["category"],
        "speciesName": species,
        "quantity": int(row["quantity"] or 1),
        "notes": notes,
        "observedAt": observed_at(row),
        "publishToWall": True,
        "visibility": "public",
        "status": "pending",
        "integrityLabel": "Pendiente",
        "evidence": [evidence],
        "photoUrl": photo_url,
        "photoThumbUrl": thumb_url,
        "mediaType": "image",
        **shared,
    }
    feed = {
        "sourceRecordId": f"fieldRecords/{record_id}",
        "authorId": AUTHOR["uid"],
        "authorName": AUTHOR["name"],
        "authorSnapshot": AUTHOR,
        "category": category,
        "speciesName": species,
        "notes": notes,
        "bodyPreview": notes,
        "photoUrl": photo_url,
        "photoThumbUrl": thumb_url,
        "mediaType": "image",
        "photoLabel": species,
        "visibility": "public",
        **shared,
    }
    return record, feed


def _download(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def _upload(bucket: Any, path: str, data: bytes) -> str:
    """Sube a Storage y devuelve una URL de descarga como las del SDK cliente."""
    token = uuid.uuid4().hex
    blob = bucket.blob(path)
    blob.metadata = {"firebaseStorageDownloadTokens": token}
    blob.upload_from_string(data, content_type="image/jpeg")
    quoted = urllib.parse.quote(path, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/{quoted}"
        f"?alt=media&token={token}"
    )


def _copy_photo(bucket: Any, row: dict[str, str], record_id: str) -> dict[str, Any]:
    photo = _download(row["photo_url"])
    thumb = _download(row["photo_thumb_url"])
    base = f"field_records/{AUTHOR['uid']}/{record_id}"
    photo_path = f"{base}/photo.jpg"
    thumb_path = f"{base}/thumb.jpg"
    photo_url = _upload(bucket, photo_path, photo)
    thumb_url = _upload(bucket, thumb_path, thumb)
    return {
        "type": "image",
        "fileName": "photo.jpg",
        "storagePath": photo_path,
        "downloadUrl": photo_url,
        "displayUrl": photo_url,
        "thumbUrl": thumb_url,
        "thumbStoragePath": thumb_path,
        "contentType": "image/jpeg",
        "sizeBytes": len(photo),
        "thumbSizeBytes": len(thumb),
        "source": SOURCE,
        "license": row["photo_license"],
        "attribution": row["observer_name"],
        "sourceUrl": row["observation_url"],
        # Hora concreta, como la app: Firestore no admite SERVER_TIMESTAMP en listas.
        "uploadedAt": datetime.now(timezone.utc),
    }


def _claim_next_index(db: Any, total: int) -> int | None:
    """Reserva la siguiente fila de la cola; `None` cuando ya no quedan."""
    cursor_ref = db.collection(CURSOR_PATH[0]).document(CURSOR_PATH[1])

    @firestore.transactional
    def _claim(transaction: firestore.Transaction) -> int | None:
        snap = cursor_ref.get(transaction=transaction)
        index = int((snap.to_dict() or {}).get("nextIndex", 0)) if snap.exists else 0
        if index >= total:
            return None
        transaction.set(
            cursor_ref,
            {"nextIndex": index + 1, "total": total, "updatedAt": firestore.SERVER_TIMESTAMP},
            merge=True,
        )
        return index

    return _claim(db.transaction())


def publish_next() -> str | None:
    """Publica el siguiente avistamiento de la cola y devuelve su id."""
    rows = load_rows()
    db = firestore.client()
    bucket = storage.bucket()

    for _ in range(MAX_ATTEMPTS):
        index = _claim_next_index(db, len(rows))
        if index is None:
            logging.warning("La cola de iNaturalist se agotó (%s filas).", len(rows))
            return None
        row = rows[index]
        record_id = f"inat-{row['inat_id']}"
        record_ref = db.collection("fieldRecords").document(record_id)
        if record_ref.get().exists:
            continue
        try:
            evidence = _copy_photo(bucket, row, record_id)
        except OSError as error:
            logging.warning("Foto no disponible para %s: %s", record_id, error)
            continue

        record, feed = build_documents(row, record_id, evidence)
        batch = db.batch()
        batch.set(record_ref, record)
        batch.set(db.collection("publicFeed").document(record_id), feed)
        batch.commit()
        logging.info("Publicado %s (%s), fila %s.", record_id, row["species_name"], index)
        return record_id

    logging.warning("No se pudo publicar tras %s intentos.", MAX_ATTEMPTS)
    return None
