"""Cloud Functions for GeoFauna server-side workflows."""

import json
import zlib
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
    """Join an event with capacity checks."""
    _require_auth(req)
    _not_implemented("join_event")
    return {"ok": True}


@https_fn.on_call(
    region=REGION,
    cors=options.CorsOptions(cors_origins=["*"], cors_methods=["post"]),
)
def validate_record(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Submit peer or expert validation for a field record."""
    _require_auth(req)
    _not_implemented("validate_record")
    return {"ok": True}


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

    for chunk in _chunks(tokens, 500):
        message = messaging.MulticastMessage(
            tokens=chunk,
            data=data_payload,
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(
                headers={"apns-priority": "10"},
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        content_available=True,
                        mutable_content=True,
                    )
                ),
            ),
        )
        _send_multicast(message)


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


def _send_multicast(message: messaging.MulticastMessage) -> None:
    sender = getattr(messaging, "send_each_for_multicast", None)
    if sender is not None:
        sender(message)
        return
    messaging.send_multicast(message)


def _chunks(values: list[str], size: int) -> list[list[str]]:
    return [values[i : i + size] for i in range(0, len(values), size)]


def _notification_id(post_id: str) -> int:
    return zlib.crc32(post_id.encode("utf-8")) & 0x7FFFFFFF


def _string_value(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None
