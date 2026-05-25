"""Cloud Functions for GeoFauna server-side workflows."""

from __future__ import annotations

import json
import logging
import zlib
from datetime import datetime, timezone
from typing import Any

from firebase_admin import firestore, initialize_app, messaging
from firebase_functions import https_fn, options
from firebase_functions.firestore_fn import (
    Event,
    DocumentSnapshot,
    on_document_created,
    on_document_updated,
)


initialize_app()

REGION = "us-central1"
WALL_CHANNEL_KEY = "wall_channel"


def _require_auth(req: https_fn.CallableRequest) -> str:
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Authentication is required.",
        )
    return req.auth.uid


def _not_implemented(name: str) -> None:
    raise https_fn.HttpsError(
        code=https_fn.FunctionsErrorCode.UNIMPLEMENTED,
        message=f"{name} is planned but not implemented yet.",
    )


def _request_data(req: https_fn.CallableRequest) -> dict[str, Any]:
    if not isinstance(req.data, dict):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Request data must be an object.",
        )
    return req.data


def _require_document_owner(
    collection: str,
    doc_id: str,
    uid: str,
) -> tuple[firestore.DocumentReference, dict[str, Any]]:
    db = firestore.client()
    ref = db.collection(collection).document(doc_id)
    snap = ref.get()
    if not snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message=f"{collection}/{doc_id} does not exist.",
        )

    data = snap.to_dict() or {}
    owner = _first_non_empty([
        _string_value(data.get("authorId")),
        _string_value(data.get("createdBy")),
    ])
    if owner != uid:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Only the author can edit this document.",
        )
    return ref, data


def _require_id(data: dict[str, Any], field: str) -> str:
    value = _string_value(data.get(field))
    if value is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"{field} is required.",
        )
    return value


def _require_datetime(data: dict[str, Any], field: str) -> datetime:
    value = data.get(field)
    if isinstance(value, datetime):
        return value
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value / 1000, tz=timezone.utc)
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            pass
    raise https_fn.HttpsError(
        code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
        message=f"{field} must be a timestamp.",
    )


def _require_int(data: dict[str, Any], field: str, minimum: int | None = None) -> int:
    value = data.get(field)
    if isinstance(value, bool):
        value = None
    if isinstance(value, (int, float)):
        parsed = int(value)
    elif isinstance(value, str):
        try:
            parsed = int(value.strip())
        except ValueError:
            parsed = None
    else:
        parsed = None
    if parsed is None or (minimum is not None and parsed < minimum):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"{field} is invalid.",
        )
    return parsed


def _bool_value(value: Any, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"1", "true", "yes", "si", "s"}
    return default


def _clean_or_delete(value: Any) -> Any:
    cleaned = _string_value(value)
    return cleaned if cleaned is not None else firestore.DELETE_FIELD


def _date_only(value: datetime) -> datetime:
    return datetime(value.year, value.month, value.day, tzinfo=value.tzinfo)


def _record_category(value: Any) -> str:
    text = (_string_value(value) or "other").lower()
    if text in {"fauna", "flora"}:
        return text
    if text in {"incident", "incidente"}:
        return "incident"
    if text in {"trash", "basura"}:
        return "trash"
    return "other"


def _category_label(key: str) -> str:
    return {
        "fauna": "Fauna",
        "flora": "Flora",
        "incident": "Incidente",
        "trash": "Basura",
    }.get(key, "Otro")


def _validate_evidence(value: Any) -> list[dict[str, Any]]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="evidence must be a list.",
        )
    evidence: list[dict[str, Any]] = []
    for item in value:
        if not isinstance(item, dict):
            continue
        media_type = _string_value(item.get("type"))
        download_url = _first_non_empty([
            _string_value(item.get("downloadUrl")),
            _string_value(item.get("displayUrl")),
            _string_value(item.get("videoUrl")),
        ])
        if media_type not in {"image", "video"} or download_url is None:
            continue
        evidence.append(dict(item))
    return evidence


def _first_image_url(evidence: list[dict[str, Any]]) -> str | None:
    for item in evidence:
        if item.get("type") == "image":
            return _first_non_empty([
                _string_value(item.get("displayUrl")),
                _string_value(item.get("downloadUrl")),
            ])
    return None


def _first_image_thumb_url(evidence: list[dict[str, Any]]) -> str | None:
    for item in evidence:
        if item.get("type") == "image":
            return _first_non_empty([
                _string_value(item.get("thumbUrl")),
                _string_value(item.get("displayUrl")),
                _string_value(item.get("downloadUrl")),
            ])
    return None


def _first_video_url(evidence: list[dict[str, Any]]) -> str | None:
    for item in evidence:
        if item.get("type") == "video":
            return _first_non_empty([
                _string_value(item.get("videoUrl")),
                _string_value(item.get("downloadUrl")),
            ])
    return None


def _first_video_thumb_url(evidence: list[dict[str, Any]]) -> str | None:
    for item in evidence:
        if item.get("type") == "video":
            return _string_value(item.get("thumbUrl"))
    return None


def _media_update_fields(evidence: list[dict[str, Any]]) -> dict[str, Any]:
    first_image_url = _first_image_url(evidence)
    first_image_thumb_url = _first_image_thumb_url(evidence)
    first_video_url = _first_video_url(evidence)
    first_video_thumb_url = _first_video_thumb_url(evidence)
    media_type = "image" if first_image_url else "video" if first_video_url else None

    return {
        "photoUrl": first_image_url or firestore.DELETE_FIELD,
        "photoThumbUrl": (
            first_image_thumb_url or first_video_thumb_url or firestore.DELETE_FIELD
        ),
        "videoUrl": first_video_url or firestore.DELETE_FIELD,
        "videoThumbUrl": first_video_thumb_url or firestore.DELETE_FIELD,
        "mediaType": media_type or firestore.DELETE_FIELD,
    }


def _write_edit_history(
    batch: firestore.WriteBatch,
    ref: firestore.DocumentReference,
    uid: str,
    changed_fields: list[str],
) -> None:
    history_ref = ref.collection("editHistory").document()
    batch.set(
        history_ref,
        {
            "editedAt": firestore.SERVER_TIMESTAMP,
            "editedBy": uid,
            "changedFields": sorted(set(changed_fields)),
        },
    )


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def create_field_record(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Create a canonical field record and optional public feed entry."""
    _require_auth(req)
    _not_implemented("create_field_record")
    return {"ok": True}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def create_tour(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Create a tour/expedition record for Agenda."""
    _require_auth(req)
    _not_implemented("create_tour")
    return {"ok": True}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def create_event(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Create a mission, workshop or cleanup event."""
    _require_auth(req)
    _not_implemented("create_event")
    return {"ok": True}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def join_event(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Join an event, enforcing capacity and single-membership in a transaction."""
    uid = _require_auth(req)
    data = _request_data(req)
    event_id = _require_id(data, "eventId")
    calendar_event_id = _string_value(data.get("calendarEventId"))

    db = firestore.client()
    event_ref = db.collection("events").document(event_id)
    participant_ref = event_ref.collection("participants").document(uid)

    @firestore.transactional
    def _join(transaction: firestore.Transaction) -> dict[str, Any]:
        snap = event_ref.get(transaction=transaction)
        if not snap.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="El evento no existe.",
            )
        event = snap.to_dict() or {}

        if _is_closed_status(_string_value(event.get("status"))):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="El evento ya no admite inscripciones.",
            )

        participant_ids = event.get("participantIds")
        participant_ids = participant_ids if isinstance(participant_ids, list) else []
        if uid in participant_ids:
            return {"ok": True, "alreadyJoined": True, "full": False}

        count = _coerce_int(event.get("participantCount"), default=len(participant_ids))
        capacity = _coerce_int(event.get("capacity"), default=None)
        if capacity is not None and count >= capacity:
            return {"ok": False, "alreadyJoined": False, "full": True}

        transaction.update(
            event_ref,
            {
                "participantIds": firestore.ArrayUnion([uid]),
                "participantCount": firestore.Increment(1),
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
        )
        transaction.set(
            participant_ref,
            {
                "userId": uid,
                "role": "participant",
                "status": "going",
                "joinedAt": firestore.SERVER_TIMESTAMP,
                "calendarEventId": calendar_event_id or firestore.DELETE_FIELD,
            },
            merge=True,
        )
        return {"ok": True, "alreadyJoined": False, "full": False}

    result = _join(db.transaction())
    if result.get("ok"):
        result["eventId"] = event_id
    return result


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def leave_event(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Leave an event. The organizer cannot leave their own event."""
    uid = _require_auth(req)
    data = _request_data(req)
    event_id = _require_id(data, "eventId")

    db = firestore.client()
    event_ref = db.collection("events").document(event_id)
    participant_ref = event_ref.collection("participants").document(uid)

    @firestore.transactional
    def _leave(transaction: firestore.Transaction) -> dict[str, Any]:
        snap = event_ref.get(transaction=transaction)
        if not snap.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message="El evento no existe.",
            )
        event = snap.to_dict() or {}
        owner = _first_non_empty([
            _string_value(event.get("authorId")),
            _string_value(event.get("createdBy")),
        ])
        if owner == uid:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="El organizador no puede abandonar su propio evento.",
            )

        participant_ids = event.get("participantIds")
        participant_ids = participant_ids if isinstance(participant_ids, list) else []
        if uid not in participant_ids:
            return {"ok": True, "wasParticipant": False}

        transaction.update(
            event_ref,
            {
                "participantIds": firestore.ArrayRemove([uid]),
                "participantCount": firestore.Increment(-1),
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
        )
        transaction.delete(participant_ref)
        return {"ok": True, "wasParticipant": True}

    result = _leave(db.transaction())
    result["eventId"] = event_id
    return result


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def validate_record(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Submit peer or expert validation for a field record."""
    _require_auth(req)
    _not_implemented("validate_record")
    return {"ok": True}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def update_field_record(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Edit a field record through the backend, only by its author."""
    uid = _require_auth(req)
    data = _request_data(req)
    record_id = _require_id(data, "recordId")
    record_ref, current = _require_document_owner("fieldRecords", record_id, uid)

    category_key = _record_category(data.get("category"))
    observed_at = _require_datetime(data, "observedAtMs")
    quantity = _require_int(data, "quantity", minimum=1)
    publish_to_wall = _bool_value(data.get("publishToWall"), default=True)
    replace_evidence = _bool_value(data.get("replaceEvidence"), default=False)
    evidence = _validate_evidence(data.get("evidence")) if replace_evidence else None

    update_data: dict[str, Any] = {
        "category": category_key,
        "categoryLabel": _category_label(category_key),
        "speciesName": _clean_or_delete(data.get("speciesName")),
        "quantity": quantity,
        "notes": _clean_or_delete(data.get("notes")),
        "observedAt": observed_at,
        "publishToWall": publish_to_wall,
        "visibility": "public" if publish_to_wall else "private",
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "editedAt": firestore.SERVER_TIMESTAMP,
        "editedBy": uid,
        "editCount": firestore.Increment(1),
    }
    if evidence is not None:
        update_data["evidence"] = evidence
        update_data.update(_media_update_fields(evidence))

    db = firestore.client()
    batch = db.batch()
    batch.update(record_ref, update_data)
    _write_edit_history(batch, record_ref, uid, list(update_data.keys()))

    feed_ref = db.collection("publicFeed").document(record_id)
    if publish_to_wall:
        current_evidence = (
            evidence
            if evidence is not None
            else _validate_evidence(current.get("evidence") or [])
        )
        media_fields = _media_update_fields(current_evidence)
        first_image_url = _first_image_url(current_evidence)
        first_video_url = _first_video_url(current_evidence)
        first_video_thumb_url = _first_video_thumb_url(current_evidence)
        species_name = _string_value(data.get("speciesName"))
        notes = _string_value(data.get("notes"))
        author_snapshot = current.get("authorSnapshot") or {}
        feed_data = {
            "sourceRecordId": f"fieldRecords/{record_id}",
            "authorId": uid,
            "authorName": current.get("authorName"),
            "authorSnapshot": author_snapshot,
            "category": category_key,
            "speciesName": species_name or firestore.DELETE_FIELD,
            "notes": notes or firestore.DELETE_FIELD,
            "bodyPreview": _first_non_empty([
                notes,
                species_name,
                _category_label(category_key),
            ]),
            "photoUrl": first_image_url or firestore.DELETE_FIELD,
            "photoThumbUrl": media_fields["photoThumbUrl"],
            "videoUrl": first_video_url or firestore.DELETE_FIELD,
            "videoThumbUrl": first_video_thumb_url or firestore.DELETE_FIELD,
            "mediaType": media_fields["mediaType"],
            "photoLabel": (
                "Video cargado"
                if first_image_url is None and first_video_url is not None
                else _first_non_empty([species_name, _category_label(category_key)])
            ),
            "placeLabel": current.get("placeLabel") or firestore.DELETE_FIELD,
            "visibility": "public",
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "editedAt": firestore.SERVER_TIMESTAMP,
            "editedBy": uid,
            "editCount": firestore.Increment(1),
        }
        batch.set(feed_ref, feed_data, merge=True)
        _write_edit_history(batch, feed_ref, uid, list(feed_data.keys()))
    else:
        batch.delete(feed_ref)

    batch.commit()
    return {"ok": True, "recordId": record_id}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def update_tour(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Edit an Agenda tour through the backend, only by its author."""
    uid = _require_auth(req)
    data = _request_data(req)
    tour_id = _require_id(data, "tourId")
    tour_ref, _ = _require_document_owner("tours", tour_id, uid)

    name = _string_value(data.get("name"))
    if name is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="name is required.",
        )
    start_at = _require_datetime(data, "startAtMs")
    end_at = _require_datetime(data, "endAtMs")
    if end_at <= start_at:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="endAt must be after startAt.",
        )

    update_data = {
        "name": name,
        "title": name,
        "type": _string_value(data.get("type")) or "Terrestre",
        "date": _date_only(start_at),
        "startAt": start_at,
        "endAt": end_at,
        "meetingPoint": _clean_or_delete(data.get("meetingPoint")),
        "locationLabel": _clean_or_delete(data.get("meetingPoint")),
        "notes": _clean_or_delete(data.get("notes")),
        "description": _clean_or_delete(data.get("notes")),
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "editedAt": firestore.SERVER_TIMESTAMP,
        "editedBy": uid,
        "editCount": firestore.Increment(1),
    }

    db = firestore.client()
    batch = db.batch()
    batch.update(tour_ref, update_data)
    _write_edit_history(batch, tour_ref, uid, list(update_data.keys()))
    batch.commit()
    return {"ok": True, "tourId": tour_id}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def update_event(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Edit an event through the backend, only by its author."""
    uid = _require_auth(req)
    data = _request_data(req)
    event_id = _require_id(data, "eventId")
    event_ref, current = _require_document_owner("events", event_id, uid)

    title = _string_value(data.get("title"))
    if title is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="title is required.",
        )
    start_at = _require_datetime(data, "startAtMs")
    end_at = _require_datetime(data, "endAtMs")
    if end_at <= start_at:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="endAt must be after startAt.",
        )

    is_public = _bool_value(data.get("isPublic"), default=True)
    update_data = {
        "title": title,
        "name": title,
        "type": _string_value(data.get("type")) or "Mision",
        "date": _date_only(start_at),
        "startAt": start_at,
        "endAt": end_at,
        "objectives": _clean_or_delete(data.get("objectives")),
        "description": _clean_or_delete(data.get("objectives")),
        "meetingPoint": _clean_or_delete(data.get("meetingPoint")),
        "locationLabel": _clean_or_delete(data.get("meetingPoint")),
        "isPublic": is_public,
        "public": is_public,
        "visibility": "public" if is_public else "private",
        "updatedAt": firestore.SERVER_TIMESTAMP,
        "editedAt": firestore.SERVER_TIMESTAMP,
        "editedBy": uid,
        "editCount": firestore.Increment(1),
    }

    # The organizer edits the maximum capacity, never the live joined count.
    # New capacity must not drop below the people already enrolled.
    capacity = _require_int(data, "capacity", minimum=0)
    current_count = _coerce_int(current.get("participantCount"), default=0) or 0
    if capacity < current_count:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message=f"El cupo no puede ser menor a los {current_count} inscritos.",
        )
    update_data["capacity"] = capacity

    db = firestore.client()
    batch = db.batch()
    batch.update(event_ref, update_data)
    _write_edit_history(batch, event_ref, uid, list(update_data.keys()))
    batch.commit()
    return {"ok": True, "eventId": event_id}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def start_tour(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Mark a tour as in progress when its author starts recording a track."""
    uid = _require_auth(req)
    data = _request_data(req)
    tour_id = _require_id(data, "tourId")
    tour_ref, _ = _require_document_owner("tours", tour_id, uid)
    tour_ref.update(
        {
            "status": "in_progress",
            "startedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
    )
    return {"ok": True, "tourId": tour_id}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def finish_tour(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Mark a tour as completed and link the recorded track."""
    uid = _require_auth(req)
    data = _request_data(req)
    tour_id = _require_id(data, "tourId")
    track_id = _string_value(data.get("trackId"))
    tour_ref, _ = _require_document_owner("tours", tour_id, uid)
    update: dict[str, Any] = {
        "status": "completed",
        "completedAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }
    if track_id is not None:
        update["trackId"] = track_id
    tour_ref.update(update)
    return {"ok": True, "tourId": tour_id}


@on_document_created(document="tracks/{trackId}", region=REGION)
def on_track_created(event: Event[DocumentSnapshot]) -> None:
    """Reconcile tour status when a track lands (e.g. via offline sync)."""
    if event.data is None:
        return
    data = event.data.to_dict() or {}
    tour_id = _string_value(data.get("tourId"))
    if tour_id is None:
        return
    db = firestore.client()
    tour_ref = db.collection("tours").document(tour_id)
    snap = tour_ref.get()
    if not snap.exists:
        return
    tour_ref.update(
        {
            "status": "completed",
            "trackId": event.params["trackId"],
            "completedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }
    )


@on_document_created(document="fieldRecords/{recordId}", region=REGION)
def on_field_record_created(event: Event[DocumentSnapshot]) -> None:
    """Update feed, integrity score and aggregates after record creation."""
    if event.data is None:
        return
    # Planned: compute sensitivity, public feed summary and aggregate stats.


@on_document_created(document="publicFeed/{postId}", region=REGION)
def on_public_feed_created(event: Event[DocumentSnapshot]) -> None:
    """Notify all other users when a public wall post is created."""
    if event.data is None:
        return

    data = event.data.to_dict() or {}
    post_id = event.params["postId"]
    author_id = _string_value(data.get("authorId"))
    source_key = _string_value(data.get("sourceRecordId")) or f"publicFeed/{post_id}"
    tokens = _notification_tokens(exclude_uid=author_id)
    if not tokens:
        return

    title = "Nueva publicacion en el muro"
    author_name = _string_value(data.get("authorName")) or "Un guia"
    species_name = _string_value(data.get("speciesName"))
    body_preview = _string_value(data.get("bodyPreview"))
    category = _string_value(data.get("category"))
    body = body_preview or species_name or f"{author_name} compartio un registro"

    content = {
        "id": _notification_id(post_id),
        "channelKey": WALL_CHANNEL_KEY,
        "title": title,
        "body": body,
        "summary": author_name,
        "notificationLayout": "Default",
        "displayOnForeground": True,
        "displayOnBackground": True,
        "wakeUpScreen": True,
        "payload": {
            "route": "wall_post",
            "postId": post_id,
            "sourceKey": source_key,
            "authorId": author_id or "",
            "category": category or "",
        },
    }

    data_payload = {
        "content": json.dumps(content, ensure_ascii=False),
        "route": "wall_post",
        "postId": post_id,
        "sourceKey": source_key,
    }

    notification = messaging.Notification(title=title, body=body)

    for chunk in _chunks(tokens, 500):
        message = messaging.MulticastMessage(
            tokens=chunk,
            notification=notification,
            data=data_payload,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id=WALL_CHANNEL_KEY,
                    title=title,
                    body=body,
                ),
            ),
            apns=messaging.APNSConfig(
                headers={"apns-priority": "10"},
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(title=title, body=body),
                        sound="default",
                        mutable_content=True,
                    )
                ),
            ),
        )
        _send_multicast(message, post_id=post_id, recipients=len(chunk))


@on_document_updated(document="fieldRecords/{recordId}", region=REGION)
def on_field_record_updated(event: Event[Any]) -> None:
    """Recompute aggregates when record status or visibility changes."""
    # Planned: compare before/after and update only affected aggregates.


@on_document_created(document="events/{eventId}", region=REGION)
def on_event_created(event: Event[DocumentSnapshot]) -> None:
    """Notify eligible users and update upcoming event summaries."""
    if event.data is None:
        return
    # Planned: FCM notification fanout and daily agenda materialization.


@on_document_created(document="tours/{tourId}", region=REGION)
def on_tour_created(event: Event[DocumentSnapshot]) -> None:
    """Materialize tour into the daily agenda."""
    if event.data is None:
        return
    # Planned: create dailyAgendas entries for guide/date.


def _notification_tokens(exclude_uid: str | None) -> list[str]:
    db = firestore.client()
    tokens: list[str] = []
    seen: set[str] = set()
    query = (
        db.collection_group("notificationTokens")
        .where("enabled", "==", True)
        .stream()
    )
    for snap in query:
        token_data = snap.to_dict() or {}
        uid = _string_value(token_data.get("userId"))
        token = _string_value(token_data.get("token"))
        if not token or token in seen:
            continue
        if exclude_uid and uid == exclude_uid:
            continue
        seen.add(token)
        tokens.append(token)
    return tokens


def _send_multicast(
    message: messaging.MulticastMessage,
    *,
    post_id: str | None = None,
    recipients: int | None = None,
) -> None:
    sender = getattr(messaging, "send_each_for_multicast", None)
    response = sender(message) if sender is not None else messaging.send_multicast(message)

    success = getattr(response, "success_count", None)
    failure = getattr(response, "failure_count", None)
    logging.info(
        "publicFeed push sent post=%s recipients=%s success=%s failure=%s",
        post_id,
        recipients,
        success,
        failure,
    )
    if failure:
        for idx, resp in enumerate(getattr(response, "responses", []) or []):
            if not getattr(resp, "success", True):
                logging.warning(
                    "publicFeed push failed post=%s token_index=%s error=%s",
                    post_id,
                    idx,
                    getattr(resp, "exception", None),
                )


def _chunks(values: list[str], size: int) -> list[list[str]]:
    return [values[i : i + size] for i in range(0, len(values), size)]


def _notification_id(post_id: str) -> int:
    return zlib.crc32(post_id.encode("utf-8")) & 0x7FFFFFFF


def _coerce_int(value: Any, default: int | None = None) -> int | None:
    if isinstance(value, bool):
        return default
    if isinstance(value, (int, float)):
        return int(value)
    if isinstance(value, str):
        try:
            return int(value.strip())
        except ValueError:
            return default
    return default


def _is_closed_status(status: str | None) -> bool:
    return (status or "").lower() in {
        "completed",
        "cancelled",
        "canceled",
        "finalizado",
        "cancelado",
        "closed",
    }


def _string_value(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _first_non_empty(values: list[str | None]) -> str | None:
    for value in values:
        cleaned = _string_value(value)
        if cleaned is not None:
            return cleaned
    return None
