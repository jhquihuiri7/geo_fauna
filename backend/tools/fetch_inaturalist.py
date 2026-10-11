"""Descarga avistamientos de Galápagos desde la API pública de iNaturalist.

Genera el CSV que la función `publish_inaturalist_sighting` publica en el Muro,
dos por día. Solo guarda observaciones de grado investigación, con coordenadas
sin ofuscar y con una foto bajo licencia Creative Commons que permite
redistribuirla con crédito (sin ND ni "todos los derechos reservados"). Deja una
observación por especie, la más marcada como favorita.

Uso (desde la raíz del repo):

    python backend/tools/fetch_inaturalist.py

Respeta el límite de la API (~1 petición por segundo).
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

API_URL = "https://api.inaturalist.org/v1/observations"
USER_AGENT = "GeoFauna/1.0 (seed del Muro)"
DEFAULT_OUTPUT = (
    Path(__file__).resolve().parents[1] / "functions" / "data" / "inaturalist_galapagos.csv"
)

# Licencias que permiten mostrar la foto tal cual con crédito, en un uso no
# comercial. Quedan fuera las ND y las que no tienen licencia.
ALLOWED_LICENSES = ("cc0", "cc-by", "cc-by-sa", "cc-by-nc", "cc-by-nc-sa")
LICENSE_LABELS = {
    "cc0": "CC0",
    "cc-by": "CC BY",
    "cc-by-sa": "CC BY-SA",
    "cc-by-nc": "CC BY-NC",
    "cc-by-nc-sa": "CC BY-NC-SA",
}

FLORA_TAXA = {"Plantae"}
FAUNA_TAXA = {
    "Animalia",
    "Aves",
    "Reptilia",
    "Mammalia",
    "Amphibia",
    "Actinopterygii",
    "Mollusca",
    "Insecta",
    "Arachnida",
}

# Códigos de región que iNaturalist agrega al final de `place_guess`.
_REGION_CODE = re.compile(r"^[A-Z]{2}(-[A-Z]{2,3})?$")

COLUMNS = [
    "inat_id",
    "category",
    "species_name",
    "scientific_name",
    "common_name",
    "quantity",
    "observed_at",
    "latitude",
    "longitude",
    "place_label",
    "place_detail",
    "description",
    "photo_url",
    "photo_thumb_url",
    "photo_license",
    "observer_name",
    "observation_url",
]


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--d1", default="2026-01-01")
    parser.add_argument("--d2", default="2026-10-10")
    parser.add_argument("--nelat", type=float, default=1.6818345)
    parser.add_argument("--nelng", type=float, default=-89.2412769)
    parser.add_argument("--swlat", type=float, default=-1.4112351)
    parser.add_argument("--swlng", type=float, default=-92.0089666)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--seed", type=int, default=42, help="orden de publicación")
    return parser.parse_args()


def _get(params: dict[str, object]) -> dict:
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except OSError as error:
            if attempt == 3:
                raise
            wait = 5 * (attempt + 1)
            print(f"  reintento en {wait}s ({error})", file=sys.stderr)
            time.sleep(wait)
    raise AssertionError("unreachable")


def _observations(args: argparse.Namespace):
    """Recorre todas las páginas por `id_above` (la API corta en 10.000 con `page`)."""
    params: dict[str, object] = {
        "d1": args.d1,
        "d2": args.d2,
        "nelat": args.nelat,
        "nelng": args.nelng,
        "swlat": args.swlat,
        "swlng": args.swlng,
        "photos": "true",
        "quality_grade": "research",
        "photo_license": ",".join(ALLOWED_LICENSES),
        "locale": "es",
        "order_by": "id",
        "order": "asc",
        "per_page": 200,
        "id_above": 0,
    }
    total = None
    seen = 0
    while True:
        page = _get(params)
        if total is None:
            total = page["total_results"]
            print(f"{total} observaciones en la consulta")
        results = page["results"]
        if not results:
            return
        seen += len(results)
        print(f"  {seen}/{total}")
        yield from results
        params["id_above"] = results[-1]["id"]
        time.sleep(1)


def _category(taxon: dict) -> str | None:
    iconic = taxon.get("iconic_taxon_name")
    if iconic in FLORA_TAXA:
        return "Flora"
    if iconic in FAUNA_TAXA:
        return "Fauna"
    return None


def _photo(observation: dict) -> dict | None:
    for photo in observation.get("photos") or []:
        if photo.get("license_code") in ALLOWED_LICENSES and photo.get("url"):
            return photo
    return None


def _sized(url: str, size: str) -> str:
    return re.sub(r"/square\.(\w+)", rf"/{size}.\1", url)


def _place(place_guess: str | None) -> tuple[str, str]:
    parts = [
        part.strip()
        for part in (place_guess or "").split(",")
        if part.strip() and not _REGION_CODE.match(part.strip())
    ]
    if not parts:
        return "Galápagos", ""
    return parts[0], ", ".join(parts[1:])


def _row(observation: dict) -> dict | None:
    taxon = observation.get("taxon") or {}
    category = _category(taxon)
    photo = _photo(observation)
    location = observation.get("location")
    if (
        category is None
        or photo is None
        or not location
        or observation.get("obscured")
        or (taxon.get("rank_level") or 99) > 10
    ):
        return None

    latitude, longitude = (float(v) for v in location.split(","))
    scientific = taxon.get("name") or ""
    common = (taxon.get("preferred_common_name") or "").strip()
    if common:
        common = common[0].upper() + common[1:]
    species_name = (
        f"{common} ({scientific})" if common and common != scientific else scientific
    )
    user = observation.get("user") or {}
    place_label, place_detail = _place(observation.get("place_guess"))

    return {
        "inat_id": observation["id"],
        "category": category,
        "species_name": species_name,
        "scientific_name": scientific,
        "common_name": common,
        "quantity": 1,
        "observed_at": observation.get("time_observed_at")
        or observation.get("observed_on")
        or "",
        "latitude": round(latitude, 6),
        "longitude": round(longitude, 6),
        "place_label": place_label,
        "place_detail": place_detail,
        "description": " ".join((observation.get("description") or "").split()),
        "photo_url": _sized(photo["url"], "large"),
        "photo_thumb_url": _sized(photo["url"], "medium"),
        "photo_license": LICENSE_LABELS[photo["license_code"]],
        "observer_name": (user.get("name") or "").strip() or user.get("login", ""),
        "observation_url": observation.get("uri")
        or f"https://www.inaturalist.org/observations/{observation['id']}",
        # Solo para elegir la mejor observación de cada especie.
        "_species_id": taxon.get("min_species_taxon_id") or taxon.get("id"),
        "_faves": observation.get("faves_count") or 0,
    }


def main() -> None:
    args = _parse_args()
    best: dict[int, dict] = {}
    skipped = 0
    for observation in _observations(args):
        row = _row(observation)
        if row is None:
            skipped += 1
            continue
        current = best.get(row["_species_id"])
        if current is None or (row["_faves"], row["inat_id"]) > (
            current["_faves"],
            current["inat_id"],
        ):
            best[row["_species_id"]] = row

    rows = list(best.values())
    # Orden de publicación mezclado (fauna y flora alternadas al azar), pero
    # reproducible para que volver a generar el CSV no cambie la cola.
    rows.sort(key=lambda r: r["inat_id"])
    random.Random(args.seed).shuffle(rows)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=COLUMNS, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)

    fauna = sum(1 for r in rows if r["category"] == "Fauna")
    print(
        f"{len(rows)} especies ({fauna} fauna, {len(rows) - fauna} flora); "
        f"{skipped} observaciones descartadas -> {args.output}"
    )


if __name__ == "__main__":
    main()
