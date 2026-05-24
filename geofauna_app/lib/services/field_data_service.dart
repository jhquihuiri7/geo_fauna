import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'location_service.dart';

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
    LocationService? locationService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _locationService = locationService ?? LocationService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final LocationService _locationService;

  Future<String> createFieldRecord({
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
    final recordRef = _firestore.collection('fieldRecords').doc();

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
      if (uploadedEvidence.isNotEmpty)
        'photoUrl': uploadedEvidence.first['downloadUrl'],
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
        'photoThumbUrl': firstImageUrl,
        if (uploadedEvidence.isNotEmpty)
          'photoLabel': firstImageUrl == null
              ? 'Video cargado'
              : _firstNonEmpty([speciesName, _categoryLabel(categoryKey)]),
        'placeLabel': location?.title,
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
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final tourRef = _firestore.collection('tours').doc();
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

  Future<String> createEvent({
    required String title,
    required String type,
    required DateTime startAt,
    required DateTime endAt,
    required bool isPublic,
    required int participantCount,
    String? objectives,
    String? meetingPoint,
  }) async {
    final user = _requireUser();
    final author = await _authorSnapshot(user);
    final eventRef = _firestore.collection('events').doc();
    await eventRef.set({
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
      'participantCount': participantCount,
      'status': 'scheduled',
      'createdBy': user.uid,
      'authorId': user.uid,
      'authorName': author.name,
      'authorSnapshot': author.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return eventRef.id;
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
  }) async {
    final safeName = _safeFileName(draft.file, index, draft.type);
    final storagePath = 'field_records/$uid/$recordId/$safeName';
    final ref = _storage.ref().child(storagePath);
    final task = await ref.putFile(
      File(draft.file.path),
      SettableMetadata(contentType: _contentType(safeName, draft.type)),
    );
    final downloadUrl = await task.ref.getDownloadURL();
    return {
      'type': draft.type.name,
      'fileName': safeName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'contentType': _contentType(safeName, draft.type),
      'sizeBytes': await File(draft.file.path).length(),
      'uploadedAt': Timestamp.now(),
    };
  }

  Future<void> _incrementUserStats(String uid, Timestamp now) {
    return _firestore.collection('userStats').doc(uid).set({
      'fieldRecordCount': FieldValue.increment(1),
      'xp': FieldValue.increment(25),
      'lastActivityAt': now,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
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
  return {
    'location': GeoPoint(location.latitude, location.longitude),
    'latitude': location.latitude,
    'longitude': location.longitude,
    'placeLabel': location.title,
    'placeName': location.title,
    'locationLabel': location.subtitle == null
        ? location.title
        : '${location.title} - ${location.subtitle}',
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

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

String _safeFileName(XFile file, int index, EvidenceType type) {
  final rawName = file.name.trim().isNotEmpty
      ? file.name.trim()
      : file.path.split(Platform.pathSeparator).last;
  final cleaned = rawName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final ext = cleaned.contains('.')
      ? ''
      : (type == EvidenceType.video ? '.mp4' : '.jpg');
  return '${DateTime.now().millisecondsSinceEpoch}_${index}_$cleaned$ext';
}

String _contentType(String fileName, EvidenceType type) {
  final lower = fileName.toLowerCase();
  if (type == EvidenceType.video) {
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

String? _firstImageUrl(List<Map<String, dynamic>> evidence) {
  for (final item in evidence) {
    if (item['type'] == EvidenceType.image.name) {
      return _stringValue(item['downloadUrl']);
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
