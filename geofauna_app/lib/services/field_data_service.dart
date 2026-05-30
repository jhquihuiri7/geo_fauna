import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'location_service.dart';
import 'media_optimization_service.dart';
import 'offline_sync_service.dart';

enum EvidenceType { image, video }

class EvidenceDraft {
  const EvidenceDraft({required this.file, required this.type});

  final XFile file;
  final EvidenceType type;
}

class FieldDataService {
  FieldDataService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    LocationService? locationService,
    MediaOptimizationService? mediaOptimizationService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _locationService = locationService ?? LocationService(),
       _mediaOptimizationService =
           mediaOptimizationService ?? const MediaOptimizationService() {
    OfflineSyncService.instance.registerProcessor(_processOfflineOperation);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final LocationService _locationService;
  final MediaOptimizationService _mediaOptimizationService;

  Future<String> createFieldRecord({
    required String category,
    required DateTime observedAt,
    required int quantity,
    required bool publishToWall,
    required List<EvidenceDraft> evidence,
    String? speciesName,
    String? notes,
  }) async {
    final recordId = _firestore.collection('fieldRecords').doc().id;
    try {
      return await _createFieldRecordOnline(
        recordId: recordId,
        category: category,
        observedAt: observedAt,
        quantity: quantity,
        publishToWall: publishToWall,
        evidence: evidence,
        speciesName: speciesName,
        notes: notes,
      );
    } catch (_) {
      await _enqueueCreateFieldRecord(
        recordId: recordId,
        category: category,
        observedAt: observedAt,
        quantity: quantity,
        publishToWall: publishToWall,
        evidence: evidence,
        speciesName: speciesName,
        notes: notes,
      );
      return recordId;
    }
  }

  Future<String> _createFieldRecordOnline({
    required String recordId,
    required String category,
    required DateTime observedAt,
    required int quantity,
    required bool publishToWall,
    required List<EvidenceDraft> evidence,
    String? speciesName,
    String? notes,
  }) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final location = await _bestEffortLocation();
    final recordRef = _firestore.collection('fieldRecords').doc(recordId);

    final uploadedEvidence = <Map<String, dynamic>>[];
    for (var i = 0; i < evidence.length; i++) {
      uploadedEvidence.add(
        await _uploadEvidence(
          uid: user.uid,
          recordId: recordRef.id,
          draft: evidence[i],
          index: i,
        ),
      );
    }

    final now = Timestamp.now();
    final categoryKey = _categoryKey(category);
    final firstImageUrl = _firstImageUrl(uploadedEvidence);
    final firstImageThumbUrl = _firstImageThumbUrl(uploadedEvidence);
    final firstVideoUrl = _firstVideoUrl(uploadedEvidence);
    final firstVideoThumbUrl = _firstVideoThumbUrl(uploadedEvidence);
    final mediaType = firstImageUrl != null
        ? 'image'
        : firstVideoUrl != null
        ? 'video'
        : null;
    final recordData = <String, dynamic>{
      'authorId': user.uid,
      'authorName': author.name,
      'authorPhotoUrl': author.photoUrl,
      'authorSnapshot': author.toMap(),
      'category': categoryKey,
      'categoryLabel': _categoryLabel(categoryKey),
      'speciesName': _cleanOrNull(speciesName),
      'quantity': quantity,
      'notes': _cleanOrNull(notes),
      'observedAt': Timestamp.fromDate(observedAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'publishToWall': publishToWall,
      'visibility': publishToWall ? 'public' : 'private',
      'status': 'pending',
      'integrityLabel': 'Pendiente',
      'validationSummary': {'confirmations': 0, 'disputes': 0},
      'reactionCounts': <String, int>{},
      'commentCount': 0,
      'evidence': uploadedEvidence,
      if (firstImageUrl != null) 'photoUrl': firstImageUrl,
      if (firstImageThumbUrl != null) 'photoThumbUrl': firstImageThumbUrl,
      if (firstVideoUrl != null) 'videoUrl': firstVideoUrl,
      if (firstVideoThumbUrl != null) 'videoThumbUrl': firstVideoThumbUrl,
      if (mediaType != null) 'mediaType': mediaType,
      if (location != null) ..._locationFields(location),
    };

    final batch = _firestore.batch()..set(recordRef, recordData);

    if (publishToWall) {
      final feedRef = _firestore.collection('publicFeed').doc(recordRef.id);
      batch.set(feedRef, {
        'sourceRecordId': 'fieldRecords/${recordRef.id}',
        'authorId': user.uid,
        'authorName': author.name,
        'authorSnapshot': author.toMap(),
        'category': categoryKey,
        'speciesName': _cleanOrNull(speciesName),
        'notes': _cleanOrNull(notes),
        'bodyPreview': _firstNonEmpty([
          notes,
          speciesName,
          _categoryLabel(categoryKey),
        ]),
        'photoUrl': firstImageUrl,
        'photoThumbUrl': firstImageThumbUrl ?? firstVideoThumbUrl,
        if (firstVideoUrl != null) 'videoUrl': firstVideoUrl,
        if (firstVideoThumbUrl != null) 'videoThumbUrl': firstVideoThumbUrl,
        if (mediaType != null) 'mediaType': mediaType,
        if (uploadedEvidence.isNotEmpty)
          'photoLabel': firstImageUrl == null
              ? 'Video cargado'
              : _firstNonEmpty([speciesName, _categoryLabel(categoryKey)]),
        if (location != null) ..._locationFields(location),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'visibility': 'public',
        'validationSummary': {'confirmations': 0, 'disputes': 0},
        'reactionCounts': <String, int>{},
        'commentCount': 0,
      });
    }

    await batch.commit();
    try {
      await _incrementUserStats(user.uid, now);
    } catch (_) {
      // The record is already saved; stats are best-effort.
    }
    return recordRef.id;
  }

  Future<String> createTour({
    required String name,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    String? meetingPoint,
    String? notes,
  }) async {
    final tourId = _firestore.collection('tours').doc().id;
    try {
      return await _createTourOnline(
        tourId: tourId,
        name: name,
        type: type,
        startAt: startAt,
        endAt: endAt,
        meetingPoint: meetingPoint,
        notes: notes,
      );
    } catch (_) {
      await _enqueueCreateTour(
        tourId: tourId,
        name: name,
        type: type,
        startAt: startAt,
        endAt: endAt,
        meetingPoint: meetingPoint,
        notes: notes,
      );
      return tourId;
    }
  }

  Future<String> _createTourOnline({
    required String tourId,
    required String name,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    String? meetingPoint,
    String? notes,
  }) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final tourRef = _firestore.collection('tours').doc(tourId);
    await tourRef.set({
      'name': name.trim(),
      'title': name.trim(),
      'type': type,
      'date': Timestamp.fromDate(_dateOnly(startAt)),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'meetingPoint': _cleanOrNull(meetingPoint),
      'locationLabel': _cleanOrNull(meetingPoint),
      'notes': _cleanOrNull(notes),
      'description': _cleanOrNull(notes),
      'status': 'scheduled',
      'createdBy': user.uid,
      'authorId': user.uid,
      'authorName': author.name,
      'authorSnapshot': author.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return tourRef.id;
  }

  /// Crea un evento. [capacity] es el cupo máximo (0 = sin límite). El
  /// organizador queda auto-inscrito como participante (participantCount: 1).
  /// Si se agendó en el calendario del teléfono, [ownerCalendarEventId] guarda
  /// el id del evento creado para poder eliminarlo si se cancela.
  Future<String> createEvent({
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int capacity,
    String? objectives,
    String? meetingPoint,
    String? ownerCalendarEventId,
  }) async {
    final eventId = _firestore.collection('events').doc().id;
    try {
      return await _createEventOnline(
        eventId: eventId,
        title: title,
        type: type,
        startAt: startAt,
        endAt: endAt,
        isPublic: isPublic,
        capacity: capacity,
        objectives: objectives,
        meetingPoint: meetingPoint,
        ownerCalendarEventId: ownerCalendarEventId,
      );
    } catch (_) {
      await _enqueueCreateEvent(
        eventId: eventId,
        title: title,
        type: type,
        startAt: startAt,
        endAt: endAt,
        isPublic: isPublic,
        capacity: capacity,
        objectives: objectives,
        meetingPoint: meetingPoint,
        ownerCalendarEventId: ownerCalendarEventId,
      );
      return eventId;
    }
  }

  Future<String> _createEventOnline({
    required String eventId,
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int capacity,
    String? objectives,
    String? meetingPoint,
    String? ownerCalendarEventId,
  }) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final eventRef = _firestore.collection('events').doc(eventId);
    final participantRef = eventRef.collection('participants').doc(user.uid);

    final batch = _firestore.batch()
      ..set(eventRef, {
        'title': title.trim(),
        'name': title.trim(),
        'type': type,
        'date': Timestamp.fromDate(_dateOnly(startAt)),
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'objectives': _cleanOrNull(objectives),
        'description': _cleanOrNull(objectives),
        'meetingPoint': _cleanOrNull(meetingPoint),
        'locationLabel': _cleanOrNull(meetingPoint),
        'isPublic': isPublic,
        'public': isPublic,
        'visibility': isPublic ? 'public' : 'private',
        // capacity 0 = sin límite (se guarda null para representarlo).
        'capacity': capacity > 0 ? capacity : null,
        'participantCount': 1,
        'participantIds': [user.uid],
        'status': 'scheduled',
        'createdBy': user.uid,
        'authorId': user.uid,
        'authorName': author.name,
        'authorSnapshot': author.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(participantRef, {
        'userId': user.uid,
        'role': 'owner',
        'status': 'going',
        'authorName': author.name,
        'authorSnapshot': author.toMap(),
        'joinedAt': FieldValue.serverTimestamp(),
        if (ownerCalendarEventId != null)
          'calendarEventId': ownerCalendarEventId,
      });
    await batch.commit();
    return eventRef.id;
  }

  /// Inscribe al usuario actual en un evento. Devuelve un [EventJoinResult] que
  /// indica si quedó inscrito, si ya lo estaba o si el cupo está lleno. El
  /// chequeo de cupo es atómico en el servidor (Cloud Function `join_event`).
  Future<EventJoinResult> joinEvent({
    required String eventId,
    String? calendarEventId,
  }) async {
    final callable = _functions.httpsCallable('join_event');
    final response = await callable.call(<String, dynamic>{
      'eventId': eventId,
      if (calendarEventId != null) 'calendarEventId': calendarEventId,
    });
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : const <String, dynamic>{};
    return EventJoinResult(
      ok: data['ok'] == true,
      full: data['full'] == true,
      alreadyJoined: data['alreadyJoined'] == true,
    );
  }

  /// Cancela la inscripción del usuario actual en un evento.
  Future<void> leaveEvent({required String eventId}) async {
    final callable = _functions.httpsCallable('leave_event');
    await callable.call(<String, dynamic>{'eventId': eventId});
  }

  /// Guarda un recorrido GPS finalizado. Intenta online primero; si la red
  /// falla, lo encola en [OfflineSyncService] para subirlo después.
  Future<String> saveTrack({
    required String trackId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int movingSeconds,
    required double distanceMeters,
    required double maxSpeedMps,
    required List<Map<String, dynamic>> points,
    String? tourId,
    String? tourName,
    String? tourType,
  }) async {
    try {
      return await _saveTrackOnline(
        trackId: trackId,
        startedAt: startedAt,
        endedAt: endedAt,
        movingSeconds: movingSeconds,
        distanceMeters: distanceMeters,
        maxSpeedMps: maxSpeedMps,
        points: points,
        tourId: tourId,
        tourName: tourName,
        tourType: tourType,
      );
    } catch (_) {
      await _enqueueSaveTrack(
        trackId: trackId,
        startedAt: startedAt,
        endedAt: endedAt,
        movingSeconds: movingSeconds,
        distanceMeters: distanceMeters,
        maxSpeedMps: maxSpeedMps,
        points: points,
        tourId: tourId,
        tourName: tourName,
        tourType: tourType,
      );
      return trackId;
    }
  }

  /// Publica un recorrido finalizado en el muro (`publicFeed`) para que pueda
  /// recibir reacciones y comentarios. El documento usa el mismo id del track,
  /// de modo que volver a publicar tras sobrescribir reemplaza el post anterior.
  Future<String> publishTrackToWall({
    required String trackId,
    required DateTime startedAt,
    required int movingSeconds,
    required double distanceMeters,
    required double maxSpeedMps,
    required List<Map<String, dynamic>> points,
    String? tourName,
    String? tourType,
    String? placeLabel,
  }) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);

    // Para el muro basta una versión ligera de la ruta; reducimos los puntos y
    // descartamos coordenadas inválidas para no publicar NaN.
    final sampled = _downsamplePoints(
      points,
      500,
    ).where(_isValidTrackPoint).toList();
    final routePoints = <Map<String, dynamic>>[
      for (final p in sampled)
        {
          'lat': (p['lat'] as num).toDouble(),
          'lng': (p['lng'] as num).toDouble(),
        },
    ];
    if (routePoints.length < 2) {
      throw StateError(
        'El recorrido no tiene puntos suficientes para publicar.',
      );
    }
    final bounds = _routeBounds(routePoints);

    final feedRef = _firestore.collection('publicFeed').doc(trackId);
    await feedRef.set({
      'authorId': user.uid,
      'authorName': author.name,
      'authorSnapshot': author.toMap(),
      'postType': 'route',
      'category': 'route',
      'bodyPreview': _routeSummaryText(
        tourName: tourName,
        distanceMeters: distanceMeters,
        movingSeconds: movingSeconds,
      ),
      'tourName': _cleanOrNull(tourName),
      'tourType': _cleanOrNull(tourType),
      'distanceMeters': distanceMeters,
      'movingSeconds': movingSeconds,
      'maxSpeedMps': maxSpeedMps,
      'pointCount': routePoints.length,
      'routePoints': routePoints,
      'routeBounds': bounds,
      'placeLabel': _cleanOrNull(placeLabel),
      'startedAt': Timestamp.fromDate(startedAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'visibility': 'public',
      'validationSummary': {'confirmations': 0, 'disputes': 0},
      'reactionCounts': <String, int>{},
      'commentCount': 0,
    });
    return feedRef.id;
  }

  /// Marca un tour como "en progreso" al iniciar su grabación. Best-effort:
  /// si no hay red o falla, no interrumpe el inicio del recorrido.
  Future<void> markTourInProgress(String tourId) async {
    try {
      await _call('start_tour', {'tourId': tourId});
    } catch (_) {
      // El estado del tour es secundario frente a la grabación en curso.
    }
  }

  Future<String> _saveTrackOnline({
    required String trackId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int movingSeconds,
    required double distanceMeters,
    required double maxSpeedMps,
    required List<Map<String, dynamic>> points,
    String? tourId,
    String? tourName,
    String? tourType,
  }) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final trackRef = _firestore.collection('tracks').doc(trackId);

    // Firestore limita el documento a 1 MB; reducimos la ruta si es muy larga.
    // Descartamos puntos con coordenadas inválidas para no guardar NaN.
    final sampled = _downsamplePoints(
      points,
      5000,
    ).where(_isValidTrackPoint).toList();
    final path = <GeoPoint>[
      for (final p in sampled)
        GeoPoint((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()),
    ];

    await trackRef.set({
      'authorId': user.uid,
      'authorName': author.name,
      'authorSnapshot': author.toMap(),
      if (tourId != null) 'tourId': tourId,
      if (tourName != null) 'tourName': tourName,
      if (tourType != null) 'tourType': tourType,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'date': Timestamp.fromDate(_dateOnly(startedAt)),
      'movingSeconds': movingSeconds,
      'distanceMeters': distanceMeters,
      'maxSpeedMps': maxSpeedMps,
      'pointCount': sampled.length,
      'path': path,
      'points': sampled,
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await _incrementTrackStats(
        user.uid,
        distanceMeters: distanceMeters,
        movingSeconds: movingSeconds,
      );
    } catch (_) {
      // Las estadísticas son best-effort; el recorrido ya quedó guardado.
    }

    if (tourId != null) {
      try {
        await _call('finish_tour', {'tourId': tourId, 'trackId': trackId});
      } catch (_) {
        // El estado del tour es best-effort: el recorrido es la fuente de verdad.
      }
    }

    return trackRef.id;
  }

  Future<void> _enqueueSaveTrack({
    required String trackId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int movingSeconds,
    required double distanceMeters,
    required double maxSpeedMps,
    required List<Map<String, dynamic>> points,
    String? tourId,
    String? tourName,
    String? tourType,
  }) {
    return OfflineSyncService.instance.enqueue(
      type: 'createTrack',
      id: trackId,
      payload: {
        'trackId': trackId,
        'startAtMs': startedAt.millisecondsSinceEpoch,
        'endAtMs': endedAt.millisecondsSinceEpoch,
        'movingSeconds': movingSeconds,
        'distanceMeters': distanceMeters,
        'maxSpeedMps': maxSpeedMps,
        'points': _downsamplePoints(points, 5000),
        'tourId': tourId,
        'tourName': tourName,
        'tourType': tourType,
      },
    );
  }

  Future<void> updateFieldRecord({
    required String recordId,
    required String category,
    required DateTime observedAt,
    required int quantity,
    required bool publishToWall,
    required bool replaceEvidence,
    List<EvidenceDraft> evidence = const [],
    String? speciesName,
    String? notes,
  }) async {
    try {
      await _updateFieldRecordOnline(
        recordId: recordId,
        category: category,
        observedAt: observedAt,
        quantity: quantity,
        publishToWall: publishToWall,
        replaceEvidence: replaceEvidence,
        evidence: evidence,
        speciesName: speciesName,
        notes: notes,
      );
    } catch (_) {
      await _enqueueUpdateFieldRecord(
        recordId: recordId,
        category: category,
        observedAt: observedAt,
        quantity: quantity,
        publishToWall: publishToWall,
        replaceEvidence: replaceEvidence,
        evidence: evidence,
        speciesName: speciesName,
        notes: notes,
      );
    }
  }

  Future<void> _updateFieldRecordOnline({
    required String recordId,
    required String category,
    required DateTime observedAt,
    required int quantity,
    required bool publishToWall,
    required bool replaceEvidence,
    List<EvidenceDraft> evidence = const [],
    String? speciesName,
    String? notes,
  }) async {
    final user = _requireUser();
    final uploadedEvidence = <Map<String, dynamic>>[];
    if (replaceEvidence) {
      for (var i = 0; i < evidence.length; i++) {
        uploadedEvidence.add(
          await _uploadEvidence(
            uid: user.uid,
            recordId: recordId,
            draft: evidence[i],
            index: i,
            callablePayload: true,
          ),
        );
      }
    }

    await _call('update_field_record', {
      'recordId': recordId,
      'category': category,
      'observedAtMs': observedAt.millisecondsSinceEpoch,
      'quantity': quantity,
      'publishToWall': publishToWall,
      'speciesName': speciesName,
      'notes': notes,
      'replaceEvidence': replaceEvidence,
      if (replaceEvidence) 'evidence': uploadedEvidence,
    });
  }

  Future<void> updateTour({
    required String tourId,
    required String name,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    String? meetingPoint,
    String? notes,
  }) async {
    try {
      await _updateTourOnline(
        tourId: tourId,
        name: name,
        type: type,
        startAt: startAt,
        endAt: endAt,
        meetingPoint: meetingPoint,
        notes: notes,
      );
    } catch (_) {
      await _enqueueUpdateTour(
        tourId: tourId,
        name: name,
        type: type,
        startAt: startAt,
        endAt: endAt,
        meetingPoint: meetingPoint,
        notes: notes,
      );
    }
  }

  Future<void> _updateTourOnline({
    required String tourId,
    required String name,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    String? meetingPoint,
    String? notes,
  }) {
    _requireUser();
    return _call('update_tour', {
      'tourId': tourId,
      'name': name,
      'type': type,
      'startAtMs': startAt.millisecondsSinceEpoch,
      'endAtMs': endAt.millisecondsSinceEpoch,
      'meetingPoint': meetingPoint,
      'notes': notes,
    });
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int capacity,
    String? objectives,
    String? meetingPoint,
  }) async {
    try {
      await _updateEventOnline(
        eventId: eventId,
        title: title,
        type: type,
        startAt: startAt,
        endAt: endAt,
        isPublic: isPublic,
        capacity: capacity,
        objectives: objectives,
        meetingPoint: meetingPoint,
      );
    } catch (_) {
      await _enqueueUpdateEvent(
        eventId: eventId,
        title: title,
        type: type,
        startAt: startAt,
        endAt: endAt,
        isPublic: isPublic,
        capacity: capacity,
        objectives: objectives,
        meetingPoint: meetingPoint,
      );
    }
  }

  Future<void> _updateEventOnline({
    required String eventId,
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int capacity,
    String? objectives,
    String? meetingPoint,
  }) {
    _requireUser();
    return _call('update_event', {
      'eventId': eventId,
      'title': title,
      'type': type,
      'startAtMs': startAt.millisecondsSinceEpoch,
      'endAtMs': endAt.millisecondsSinceEpoch,
      'isPublic': isPublic,
      'capacity': capacity,
      'objectives': objectives,
      'meetingPoint': meetingPoint,
    });
  }

  Future<void> _enqueueCreateFieldRecord({
    required String recordId,
    required String category,
    required DateTime observedAt,
    required int quantity,
    required bool publishToWall,
    required List<EvidenceDraft> evidence,
    String? speciesName,
    String? notes,
  }) async {
    final localEvidence = await _persistEvidenceForQueue(evidence);
    await OfflineSyncService.instance.enqueue(
      type: 'createFieldRecord',
      payload: {
        'recordId': recordId,
        'category': category,
        'observedAtMs': observedAt.millisecondsSinceEpoch,
        'quantity': quantity,
        'publishToWall': publishToWall,
        'speciesName': speciesName,
        'notes': notes,
        'evidence': localEvidence,
      },
    );
  }

  Future<void> _enqueueUpdateFieldRecord({
    required String recordId,
    required String category,
    required DateTime observedAt,
    required int quantity,
    required bool publishToWall,
    required bool replaceEvidence,
    required List<EvidenceDraft> evidence,
    String? speciesName,
    String? notes,
  }) async {
    final localEvidence = replaceEvidence
        ? await _persistEvidenceForQueue(evidence)
        : const <Map<String, dynamic>>[];
    await OfflineSyncService.instance.enqueue(
      type: 'updateFieldRecord',
      payload: {
        'recordId': recordId,
        'category': category,
        'observedAtMs': observedAt.millisecondsSinceEpoch,
        'quantity': quantity,
        'publishToWall': publishToWall,
        'replaceEvidence': replaceEvidence,
        'speciesName': speciesName,
        'notes': notes,
        'evidence': localEvidence,
      },
    );
  }

  Future<void> _enqueueCreateTour({
    required String tourId,
    required String name,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    String? meetingPoint,
    String? notes,
  }) {
    return OfflineSyncService.instance.enqueue(
      type: 'createTour',
      payload: {
        'tourId': tourId,
        'name': name,
        'type': type,
        'startAtMs': startAt.millisecondsSinceEpoch,
        'endAtMs': endAt.millisecondsSinceEpoch,
        'meetingPoint': meetingPoint,
        'notes': notes,
      },
    );
  }

  Future<void> _enqueueUpdateTour({
    required String tourId,
    required String name,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    String? meetingPoint,
    String? notes,
  }) {
    return OfflineSyncService.instance.enqueue(
      type: 'updateTour',
      payload: {
        'tourId': tourId,
        'name': name,
        'type': type,
        'startAtMs': startAt.millisecondsSinceEpoch,
        'endAtMs': endAt.millisecondsSinceEpoch,
        'meetingPoint': meetingPoint,
        'notes': notes,
      },
    );
  }

  Future<void> _enqueueCreateEvent({
    required String eventId,
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int capacity,
    String? objectives,
    String? meetingPoint,
    String? ownerCalendarEventId,
  }) {
    return OfflineSyncService.instance.enqueue(
      type: 'createEvent',
      payload: {
        'eventId': eventId,
        'title': title,
        'type': type,
        'startAtMs': startAt.millisecondsSinceEpoch,
        'endAtMs': endAt.millisecondsSinceEpoch,
        'isPublic': isPublic,
        'capacity': capacity,
        'objectives': objectives,
        'meetingPoint': meetingPoint,
        'ownerCalendarEventId': ownerCalendarEventId,
      },
    );
  }

  Future<void> _enqueueUpdateEvent({
    required String eventId,
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int capacity,
    String? objectives,
    String? meetingPoint,
  }) {
    return OfflineSyncService.instance.enqueue(
      type: 'updateEvent',
      payload: {
        'eventId': eventId,
        'title': title,
        'type': type,
        'startAtMs': startAt.millisecondsSinceEpoch,
        'endAtMs': endAt.millisecondsSinceEpoch,
        'isPublic': isPublic,
        'capacity': capacity,
        'objectives': objectives,
        'meetingPoint': meetingPoint,
      },
    );
  }

  Future<void> _processOfflineOperation(OfflineSyncOperation operation) async {
    final payload = operation.payload;
    switch (operation.type) {
      case 'createFieldRecord':
        await _createFieldRecordOnline(
          recordId: _requiredString(payload, 'recordId'),
          category: _requiredString(payload, 'category'),
          observedAt: _dateFromMs(payload['observedAtMs']),
          quantity: _requiredInt(payload, 'quantity'),
          publishToWall: payload['publishToWall'] == true,
          evidence: _evidenceDraftsFromQueue(payload['evidence']),
          speciesName: _stringValue(payload['speciesName']),
          notes: _stringValue(payload['notes']),
        );
      case 'updateFieldRecord':
        await _updateFieldRecordOnline(
          recordId: _requiredString(payload, 'recordId'),
          category: _requiredString(payload, 'category'),
          observedAt: _dateFromMs(payload['observedAtMs']),
          quantity: _requiredInt(payload, 'quantity'),
          publishToWall: payload['publishToWall'] == true,
          replaceEvidence: payload['replaceEvidence'] == true,
          evidence: _evidenceDraftsFromQueue(payload['evidence']),
          speciesName: _stringValue(payload['speciesName']),
          notes: _stringValue(payload['notes']),
        );
      case 'createTour':
        await _createTourOnline(
          tourId: _requiredString(payload, 'tourId'),
          name: _requiredString(payload, 'name'),
          type: _requiredString(payload, 'type'),
          startAt: _dateFromMs(payload['startAtMs']),
          endAt: _dateFromMs(payload['endAtMs']),
          meetingPoint: _stringValue(payload['meetingPoint']),
          notes: _stringValue(payload['notes']),
        );
      case 'updateTour':
        await _updateTourOnline(
          tourId: _requiredString(payload, 'tourId'),
          name: _requiredString(payload, 'name'),
          type: _requiredString(payload, 'type'),
          startAt: _dateFromMs(payload['startAtMs']),
          endAt: _dateFromMs(payload['endAtMs']),
          meetingPoint: _stringValue(payload['meetingPoint']),
          notes: _stringValue(payload['notes']),
        );
      case 'createEvent':
        await _createEventOnline(
          eventId: _requiredString(payload, 'eventId'),
          title: _requiredString(payload, 'title'),
          type: _requiredString(payload, 'type'),
          startAt: _dateFromMs(payload['startAtMs']),
          endAt: _dateFromMs(payload['endAtMs']),
          isPublic: payload['isPublic'] != false,
          capacity: _requiredInt(payload, 'capacity'),
          objectives: _stringValue(payload['objectives']),
          meetingPoint: _stringValue(payload['meetingPoint']),
          ownerCalendarEventId: _stringValue(payload['ownerCalendarEventId']),
        );
      case 'updateEvent':
        await _updateEventOnline(
          eventId: _requiredString(payload, 'eventId'),
          title: _requiredString(payload, 'title'),
          type: _requiredString(payload, 'type'),
          startAt: _dateFromMs(payload['startAtMs']),
          endAt: _dateFromMs(payload['endAtMs']),
          isPublic: payload['isPublic'] != false,
          capacity: _requiredInt(payload, 'capacity'),
          objectives: _stringValue(payload['objectives']),
          meetingPoint: _stringValue(payload['meetingPoint']),
        );
      case 'createTrack':
        await _saveTrackOnline(
          trackId: _requiredString(payload, 'trackId'),
          startedAt: _dateFromMs(payload['startAtMs']),
          endedAt: _dateFromMs(payload['endAtMs']),
          movingSeconds: _requiredInt(payload, 'movingSeconds'),
          distanceMeters: _toDouble(payload['distanceMeters']) ?? 0,
          maxSpeedMps: _toDouble(payload['maxSpeedMps']) ?? 0,
          points: _pointsFromQueue(payload['points']),
          tourId: _stringValue(payload['tourId']),
          tourName: _stringValue(payload['tourName']),
          tourType: _stringValue(payload['tourType']),
        );
      default:
        throw StateError('Operacion offline no soportada: ${operation.type}');
    }
  }

  Future<List<Map<String, dynamic>>> _persistEvidenceForQueue(
    List<EvidenceDraft> evidence,
  ) {
    return OfflineSyncService.instance.persistEvidenceDrafts([
      for (final draft in evidence)
        OfflineEvidenceDraft(
          type: draft.type.name,
          path: draft.file.path,
          name: draft.file.name,
        ),
    ]);
  }

  Future<void> _call(String name, Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable(name);
    await callable.call(data);
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Debes iniciar sesion para guardar datos.',
      );
    }
    return user;
  }

  Future<_AuthorSnapshot> _authorSnapshot(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    return _AuthorSnapshot(
      uid: user.uid,
      name:
          _firstNonEmpty([
            _stringValue(data['name']),
            user.displayName,
            user.email,
          ]) ??
          'Usuario sin nombre',
      photoUrl: _firstNonEmpty([
        _stringValue(data['photoUrl']),
        _stringValue(data['photoURL']),
        user.photoURL,
      ]),
      rangerId: _stringValue(data['rangerId']),
      userType: _stringValue(data['userType']),
      specialty: _stringValue(data['specialty']),
    );
  }

  Future<UserLocation?> _bestEffortLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _uploadEvidence({
    required String uid,
    required String recordId,
    required EvidenceDraft draft,
    required int index,
    bool callablePayload = false,
  }) async {
    final prepared = await _mediaOptimizationService.prepare(
      file: draft.file,
      type: draft.type == EvidenceType.image
          ? MediaUploadType.image
          : MediaUploadType.video,
      index: index,
    );
    final storagePath =
        'field_records/$uid/$recordId/${prepared.primaryFileName}';
    final downloadUrl = await _uploadFile(
      path: storagePath,
      file: prepared.primaryFile,
      contentType: prepared.primaryContentType,
    );

    String? thumbnailUrl;
    String? thumbnailStoragePath;
    final thumbnailFile = prepared.thumbnailFile;
    final thumbnailName = prepared.thumbnailFileName;
    if (thumbnailFile != null && thumbnailName != null) {
      try {
        thumbnailStoragePath = 'field_records/$uid/$recordId/$thumbnailName';
        thumbnailUrl = await _uploadFile(
          path: thumbnailStoragePath,
          file: thumbnailFile,
          contentType: 'image/jpeg',
        );
      } catch (_) {
        thumbnailUrl = null;
        thumbnailStoragePath = null;
      }
    }

    return {
      'type': draft.type.name,
      'fileName': prepared.primaryFileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      if (draft.type == EvidenceType.image) 'displayUrl': downloadUrl,
      if (draft.type == EvidenceType.video) 'videoUrl': downloadUrl,
      if (thumbnailUrl != null) 'thumbUrl': thumbnailUrl,
      if (thumbnailStoragePath != null)
        'thumbStoragePath': thumbnailStoragePath,
      'contentType': prepared.primaryContentType,
      'sizeBytes': prepared.primarySizeBytes,
      'originalSizeBytes': prepared.originalSizeBytes,
      if (prepared.thumbnailSizeBytes != null)
        'thumbSizeBytes': prepared.thumbnailSizeBytes,
      if (prepared.width != null) 'width': prepared.width,
      if (prepared.height != null) 'height': prepared.height,
      if (prepared.durationMs != null) 'durationMs': prepared.durationMs,
      'compression': {
        'optimized': prepared.optimized,
        'originalSizeBytes': prepared.originalSizeBytes,
        'outputSizeBytes': prepared.primarySizeBytes,
        'savedBytes': prepared.originalSizeBytes - prepared.primarySizeBytes > 0
            ? prepared.originalSizeBytes - prepared.primarySizeBytes
            : 0,
      },
      'uploadedAt': callablePayload
          ? DateTime.now().millisecondsSinceEpoch
          : Timestamp.now(),
    };
  }

  Future<String> _uploadFile({
    required String path,
    required File file,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> _incrementUserStats(String uid, Timestamp now) {
    return _firestore.collection('userStats').doc(uid).set({
      'fieldRecordCount': FieldValue.increment(1),
      'xp': FieldValue.increment(25),
      'lastActivityAt': now,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _incrementTrackStats(
    String uid, {
    required double distanceMeters,
    required int movingSeconds,
  }) {
    return _firestore.collection('userStats').doc(uid).set({
      'trackCount': FieldValue.increment(1),
      'trackDistanceMeters': FieldValue.increment(distanceMeters),
      'fieldSeconds': FieldValue.increment(movingSeconds),
      'xp': FieldValue.increment(50),
      'lastActivityAt': Timestamp.now(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Resultado de intentar inscribirse en un evento vía `join_event`.
class EventJoinResult {
  const EventJoinResult({
    required this.ok,
    required this.full,
    required this.alreadyJoined,
  });

  /// La inscripción se concretó (o ya estaba inscrito).
  final bool ok;

  /// El cupo está completo y no se pudo inscribir.
  final bool full;

  /// El usuario ya estaba inscrito previamente.
  final bool alreadyJoined;
}

class _AuthorSnapshot {
  const _AuthorSnapshot({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.rangerId,
    this.userType,
    this.specialty,
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final String? rangerId;
  final String? userType;
  final String? specialty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (rangerId != null) 'rangerId': rangerId,
      if (userType != null) 'userType': userType,
      if (specialty != null) 'specialty': specialty,
    };
  }
}

Map<String, dynamic> _locationFields(UserLocation location) {
  final fields = <String, dynamic>{
    'placeLabel': location.title,
    'placeName': location.title,
    'locationLabel': location.subtitle == null
        ? location.title
        : '${location.title} - ${location.subtitle}',
  };
  // Solo guardamos coordenadas válidas; nunca NaN/Infinity ni fuera de rango,
  // para no corromper documentos que luego rompen el mapa.
  final lat = location.latitude;
  final lng = location.longitude;
  if (lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180) {
    fields['location'] = GeoPoint(lat, lng);
    fields['latitude'] = lat;
    fields['longitude'] = lng;
  }
  return fields;
}

/// Valida un punto crudo `{lat, lng}` antes de escribirlo: numérico, finito y
/// dentro de rango.
bool _isValidTrackPoint(Map<String, dynamic> point) {
  final lat = point['lat'];
  final lng = point['lng'];
  if (lat is! num || lng is! num) return false;
  final dLat = lat.toDouble();
  final dLng = lng.toDouble();
  return dLat.isFinite && dLng.isFinite && dLat.abs() <= 90 && dLng.abs() <= 180;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

Map<String, double> _routeBounds(List<Map<String, dynamic>> points) {
  var minLat = double.infinity;
  var minLng = double.infinity;
  var maxLat = -double.infinity;
  var maxLng = -double.infinity;
  for (final p in points) {
    final lat = (p['lat'] as num).toDouble();
    final lng = (p['lng'] as num).toDouble();
    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
    if (lng < minLng) minLng = lng;
    if (lng > maxLng) maxLng = lng;
  }
  return {
    'minLat': minLat,
    'minLng': minLng,
    'maxLat': maxLat,
    'maxLng': maxLng,
  };
}

String _routeSummaryText({
  String? tourName,
  required double distanceMeters,
  required int movingSeconds,
}) {
  final distance = distanceMeters < 1000
      ? '${distanceMeters.round()} m'
      : '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  final minutes = (movingSeconds / 60).round();
  final duration = minutes < 60
      ? '$minutes min'
      : '${minutes ~/ 60} h ${minutes % 60} min';
  final prefix = _cleanOrNull(tourName) ?? 'Recorrido de campo';
  return '$prefix · $distance en $duration';
}

String _categoryKey(String value) {
  final v = value.trim().toLowerCase();
  return switch (v) {
    'fauna' => 'fauna',
    'flora' => 'flora',
    'incidente' => 'incident',
    'basura' => 'trash',
    _ => 'other',
  };
}

String _categoryLabel(String key) {
  return switch (key) {
    'fauna' => 'Fauna',
    'flora' => 'Flora',
    'incident' => 'Incidente',
    'trash' => 'Basura',
    _ => 'Otro',
  };
}

String? _firstImageUrl(List<Map<String, dynamic>> evidence) {
  for (final item in evidence) {
    if (item['type'] == EvidenceType.image.name) {
      return _firstNonEmpty([
        _stringValue(item['displayUrl']),
        _stringValue(item['downloadUrl']),
      ]);
    }
  }
  return null;
}

String? _firstImageThumbUrl(List<Map<String, dynamic>> evidence) {
  for (final item in evidence) {
    if (item['type'] == EvidenceType.image.name) {
      return _firstNonEmpty([
        _stringValue(item['thumbUrl']),
        _stringValue(item['displayUrl']),
        _stringValue(item['downloadUrl']),
      ]);
    }
  }
  return null;
}

String? _firstVideoUrl(List<Map<String, dynamic>> evidence) {
  for (final item in evidence) {
    if (item['type'] == EvidenceType.video.name) {
      return _firstNonEmpty([
        _stringValue(item['videoUrl']),
        _stringValue(item['downloadUrl']),
      ]);
    }
  }
  return null;
}

String? _firstVideoThumbUrl(List<Map<String, dynamic>> evidence) {
  for (final item in evidence) {
    if (item['type'] == EvidenceType.video.name) {
      return _stringValue(item['thumbUrl']);
    }
  }
  return null;
}

String? _cleanOrNull(String? value) {
  final cleaned = value?.trim();
  if (cleaned == null || cleaned.isEmpty) return null;
  return cleaned;
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final cleaned = _cleanOrNull(value);
    if (cleaned != null) return cleaned;
  }
  return null;
}

String _requiredString(Map<String, dynamic> payload, String key) {
  final value = _stringValue(payload[key]);
  if (value == null) {
    throw StateError('Falta el campo requerido $key en la cola offline.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value is num) return value.round();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw StateError('El campo $key no es numerico en la cola offline.');
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Reduce uniformemente la cantidad de puntos a [maxPoints] conservando
/// siempre el primero y el último, para no exceder el límite de Firestore.
List<Map<String, dynamic>> _downsamplePoints(
  List<Map<String, dynamic>> points,
  int maxPoints,
) {
  if (points.length <= maxPoints) {
    return [for (final p in points) Map<String, dynamic>.from(p)];
  }
  final step = points.length / maxPoints;
  final result = <Map<String, dynamic>>[];
  for (var i = 0; i < maxPoints; i++) {
    result.add(Map<String, dynamic>.from(points[(i * step).floor()]));
  }
  result[result.length - 1] = Map<String, dynamic>.from(points.last);
  return result;
}

List<Map<String, dynamic>> _pointsFromQueue(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

DateTime _dateFromMs(Object? value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.round());
  }
  if (value is String) {
    final ms = int.tryParse(value);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  throw StateError('Fecha invalida en la cola offline.');
}

List<EvidenceDraft> _evidenceDraftsFromQueue(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map && _stringValue(item['path']) != null)
        EvidenceDraft(
          file: XFile(
            _stringValue(item['path'])!,
            name: _stringValue(item['name']),
          ),
          type: _stringValue(item['type']) == EvidenceType.video.name
              ? EvidenceType.video
              : EvidenceType.image,
        ),
  ];
}
