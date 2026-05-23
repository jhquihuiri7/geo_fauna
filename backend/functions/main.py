"""Initial Cloud Functions plan for GeoFauna.

This file intentionally keeps business logic as stubs. The concrete
implementation should be added after Firebase Emulator Suite is configured and
the Flutter client contracts are finalized.
"""

from typing import Any

from firebase_admin import initialize_app
from firebase_functions import https_fn, options
from firebase_functions.firestore_fn import (
    Event,
    DocumentSnapshot,
    on_document_created,
    on_document_updated,
)


initialize_app()

REGION = "us-central1"


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

