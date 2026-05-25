import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'field_data_service.dart';
import 'location_service.dart';

/// Un punto del recorrido grabado por el GPS.
@immutable
class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.tMs,
    this.accuracy,
    this.speed,
    this.altitude,
  });

  final double lat;
  final double lng;
  final int tMs;
  final double? accuracy;
  final double? speed;
  final double? altitude;

  LatLng get latLng => LatLng(lat, lng);

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        't': tMs,
        if (accuracy != null) 'acc': accuracy,
        if (speed != null) 'spd': speed,
        if (altitude != null) 'alt': altitude,
      };

  static TrackPoint fromJson(Map<String, dynamic> json) => TrackPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        tMs: (json['t'] as num).round(),
        accuracy: (json['acc'] as num?)?.toDouble(),
        speed: (json['spd'] as num?)?.toDouble(),
        altitude: (json['alt'] as num?)?.toDouble(),
      );
}

enum TrackStatus { recording, paused }

/// Instantánea inmutable del recorrido en curso. El servicio publica una nueva
/// cada vez que algo cambia, para que la UI reaccione vía [ValueNotifier].
@immutable
class TrackingSession {
  const TrackingSession({
    required this.trackId,
    required this.status,
    required this.points,
    required this.startedAtMs,
    required this.distanceMeters,
    required this.maxSpeedMps,
    required this.accumulatedMovingMs,
    required this.segmentStartMs,
    this.tourId,
    this.tourName,
    this.tourType,
  });

  final String trackId;
  final TrackStatus status;
  final List<TrackPoint> points;
  final int startedAtMs;

  /// Distancia acumulada en metros (suma de tramos consecutivos).
  final double distanceMeters;
  final double maxSpeedMps;

  /// Milisegundos en movimiento acumulados de tramos ya cerrados (pausas).
  final int accumulatedMovingMs;

  /// Inicio del tramo de grabación actual; `null` si está en pausa.
  final int? segmentStartMs;

  final String? tourId;
  final String? tourName;
  final String? tourType;

  bool get isPaused => status == TrackStatus.paused;
  bool get isRecording => status == TrackStatus.recording;

  TrackPoint? get lastPoint => points.isEmpty ? null : points.last;

  /// Tiempo en movimiento hasta [now] (excluye las pausas).
  Duration movingDuration([DateTime? now]) {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final live = segmentStartMs != null ? nowMs - segmentStartMs! : 0;
    return Duration(milliseconds: accumulatedMovingMs + live);
  }

  /// Velocidad media en m/s sobre el tiempo en movimiento.
  double avgSpeedMps([DateTime? now]) {
    final secs = movingDuration(now).inSeconds;
    if (secs <= 0) return 0;
    return distanceMeters / secs;
  }

  double? get currentSpeedMps => lastPoint?.speed;

  TrackingSession copyWith({
    TrackStatus? status,
    List<TrackPoint>? points,
    double? distanceMeters,
    double? maxSpeedMps,
    int? accumulatedMovingMs,
    int? segmentStartMs,
    bool clearSegmentStart = false,
  }) {
    return TrackingSession(
      trackId: trackId,
      status: status ?? this.status,
      points: points ?? this.points,
      startedAtMs: startedAtMs,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      accumulatedMovingMs: accumulatedMovingMs ?? this.accumulatedMovingMs,
      segmentStartMs:
          clearSegmentStart ? null : segmentStartMs ?? this.segmentStartMs,
      tourId: tourId,
      tourName: tourName,
      tourType: tourType,
    );
  }

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'status': status.name,
        'startedAtMs': startedAtMs,
        'distanceMeters': distanceMeters,
        'maxSpeedMps': maxSpeedMps,
        'accumulatedMovingMs': accumulatedMovingMs,
        'segmentStartMs': segmentStartMs,
        if (tourId != null) 'tourId': tourId,
        if (tourName != null) 'tourName': tourName,
        if (tourType != null) 'tourType': tourType,
        'points': [for (final p in points) p.toJson()],
      };

  static TrackingSession fromJson(Map<String, dynamic> json) {
    return TrackingSession(
      trackId: json['trackId'] as String,
      status: TrackStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TrackStatus.paused,
      ),
      points: [
        for (final item in (json['points'] as List? ?? const []))
          if (item is Map)
            TrackPoint.fromJson(Map<String, dynamic>.from(item)),
      ],
      startedAtMs: (json['startedAtMs'] as num).round(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      maxSpeedMps: (json['maxSpeedMps'] as num?)?.toDouble() ?? 0,
      accumulatedMovingMs: (json['accumulatedMovingMs'] as num?)?.round() ?? 0,
      segmentStartMs: (json['segmentStartMs'] as num?)?.round(),
      tourId: json['tourId'] as String?,
      tourName: json['tourName'] as String?,
      tourType: json['tourType'] as String?,
    );
  }
}

/// Resumen devuelto al finalizar, para la pantalla de cierre y el compartir.
class TrackSummary {
  const TrackSummary({
    required this.trackId,
    required this.distanceMeters,
    required this.movingDuration,
    required this.maxSpeedMps,
    required this.points,
    required this.startedAt,
    required this.endedAt,
    required this.saved,
    this.tourName,
  });

  final String trackId;
  final double distanceMeters;
  final Duration movingDuration;
  final double maxSpeedMps;
  final List<TrackPoint> points;
  final DateTime startedAt;
  final DateTime endedAt;

  /// `true` si llegó a Firestore; `false` si quedó en cola offline.
  final bool saved;
  final String? tourName;
}

/// Gestiona el ciclo de vida de la grabación de un recorrido de campo:
/// inicio/pausa/reanudar/finalizar, métricas en vivo, persistencia local para
/// sobrevivir a un cierre de la app, y subida (online u offline) al backend.
class TrackingService {
  TrackingService._();

  static final TrackingService instance = TrackingService._();

  final ValueNotifier<TrackingSession?> session =
      ValueNotifier<TrackingSession?>(null);

  final LocationService _locationService = LocationService();
  final FieldDataService _dataService = FieldDataService();
  static const _distance = Distance();

  StreamSubscription<Position>? _positionSub;
  File? _sessionFile;
  bool _initialized = false;
  int _pointsSinceFlush = 0;

  bool get isActive => session.value != null;

  /// Carga (si existe) una grabación que quedó abierta por un cierre abrupto.
  /// Se restaura en pausa para que el usuario decida reanudar o descartar.
  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _sessionFile =
        File('${dir.path}${Platform.pathSeparator}active_track.json');
    if (await _sessionFile!.exists()) {
      try {
        final raw = await _sessionFile!.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final recovered = TrackingSession.fromJson(
            Map<String, dynamic>.from(decoded),
          ).copyWith(status: TrackStatus.paused, clearSegmentStart: true);
          session.value = recovered;
        }
      } catch (_) {
        await _deleteSessionFile();
      }
    }
    _initialized = true;
  }

  /// Comienza un recorrido nuevo. Lanza si faltan permisos/GPS.
  ///
  /// Si se entrega [trackId], se reutiliza ese id en lugar de generar uno
  /// nuevo, de modo que al guardar se sobrescribe el recorrido anterior (y su
  /// publicación en el muro, que comparte el mismo id).
  Future<void> start({
    String? tourId,
    String? tourName,
    String? tourType,
    String? trackId,
  }) async {
    await initialize();
    if (isActive) return;
    await _locationService.ensureTrackingPermission();

    final now = DateTime.now().millisecondsSinceEpoch;
    session.value = TrackingSession(
      trackId: trackId ?? 'track_${now}_${now.toRadixString(36)}',
      status: TrackStatus.recording,
      points: <TrackPoint>[],
      startedAtMs: now,
      distanceMeters: 0,
      maxSpeedMps: 0,
      accumulatedMovingMs: 0,
      segmentStartMs: now,
      tourId: tourId,
      tourName: tourName,
      tourType: tourType,
    );
    await _enableWakelock();
    _subscribe();
    await _flush();

    if (tourId != null) {
      unawaited(_dataService.markTourInProgress(tourId));
    }
  }

  void pause() {
    final current = session.value;
    if (current == null || current.isPaused) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final closed = current.segmentStartMs != null
        ? nowMs - current.segmentStartMs!
        : 0;
    session.value = current.copyWith(
      status: TrackStatus.paused,
      accumulatedMovingMs: current.accumulatedMovingMs + closed,
      clearSegmentStart: true,
    );
    unawaited(_flush());
  }

  Future<void> resume() async {
    final current = session.value;
    if (current == null || current.isRecording) return;
    await _locationService.ensureTrackingPermission();
    session.value = current.copyWith(
      status: TrackStatus.recording,
      segmentStartMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _enableWakelock();
    if (_positionSub == null) _subscribe();
    await _flush();
  }

  /// Finaliza, sube el recorrido (online u offline) y limpia el estado.
  Future<TrackSummary> stop() async {
    final current = session.value;
    if (current == null) {
      throw StateError('No hay un recorrido activo.');
    }
    // Cierra el tramo de movimiento en curso.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final live =
        current.segmentStartMs != null ? nowMs - current.segmentStartMs! : 0;
    final movingMs = current.accumulatedMovingMs + live;

    await _teardown();

    final startedAt = DateTime.fromMillisecondsSinceEpoch(current.startedAtMs);
    final endedAt = DateTime.fromMillisecondsSinceEpoch(nowMs);

    var saved = true;
    try {
      await _dataService.saveTrack(
        trackId: current.trackId,
        tourId: current.tourId,
        tourName: current.tourName,
        tourType: current.tourType,
        startedAt: startedAt,
        endedAt: endedAt,
        movingSeconds: (movingMs / 1000).round(),
        distanceMeters: current.distanceMeters,
        maxSpeedMps: current.maxSpeedMps,
        points: [for (final p in current.points) p.toJson()],
      );
    } catch (_) {
      // saveTrack ya encola offline ante fallos de red; si igual lanza, el
      // recorrido se conserva en disco para reintentar al reabrir.
      saved = false;
    }

    if (saved) {
      await _deleteSessionFile();
      session.value = null;
    }

    return TrackSummary(
      trackId: current.trackId,
      distanceMeters: current.distanceMeters,
      movingDuration: Duration(milliseconds: movingMs),
      maxSpeedMps: current.maxSpeedMps,
      points: List<TrackPoint>.unmodifiable(current.points),
      startedAt: startedAt,
      endedAt: endedAt,
      saved: saved,
      tourName: current.tourName,
    );
  }

  /// Descarta el recorrido en curso sin guardarlo.
  Future<void> discard() async {
    await _teardown();
    await _deleteSessionFile();
    session.value = null;
  }

  // ── interno ────────────────────────────────────────────────────────────

  void _subscribe() {
    _positionSub?.cancel();
    _positionSub = _locationService
        .trackPositionStream()
        .listen(_onPosition, onError: (_) {});
  }

  void _onPosition(Position pos) {
    final current = session.value;
    if (current == null || !current.isRecording) return;
    // Descarta lecturas de baja precisión (ruido del GPS).
    if (pos.accuracy > 0 && pos.accuracy > 50) return;

    final point = TrackPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      tMs: DateTime.now().millisecondsSinceEpoch,
      accuracy: pos.accuracy,
      speed: pos.speed >= 0 ? pos.speed : null,
      altitude: pos.altitude,
    );

    var addedDistance = 0.0;
    final last = current.lastPoint;
    if (last != null) {
      addedDistance = _distance.as(LengthUnit.Meter, last.latLng, point.latLng);
      // Salto imposible (teletransporte por error de fix): ignóralo.
      if (addedDistance > 200 && (point.tMs - last.tMs) < 2000) return;
    }

    final speed = point.speed ?? 0;
    session.value = current.copyWith(
      points: [...current.points, point],
      distanceMeters: current.distanceMeters + addedDistance,
      maxSpeedMps: speed > current.maxSpeedMps ? speed : current.maxSpeedMps,
    );

    _pointsSinceFlush++;
    if (_pointsSinceFlush >= 5) {
      _pointsSinceFlush = 0;
      unawaited(_flush());
    }
  }

  Future<void> _teardown() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _disableWakelock();
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  Future<void> _flush() async {
    final file = _sessionFile;
    final current = session.value;
    if (file == null || current == null) return;
    try {
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(current.toJson()), flush: true);
      if (await file.exists()) await file.delete();
      await tmp.rename(file.path);
    } catch (_) {
      // Persistencia best-effort; la grabación en memoria sigue intacta.
    }
  }

  Future<void> _deleteSessionFile() async {
    try {
      if (_sessionFile != null && await _sessionFile!.exists()) {
        await _sessionFile!.delete();
      }
    } catch (_) {}
  }
}

/// Genera un documento GPX 1.1 a partir de los puntos del recorrido.
String buildGpx(
  List<TrackPoint> points, {
  required DateTime startedAt,
  String name = 'Recorrido GeoFauna',
}) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="GeoFauna" '
        'xmlns="http://www.topografix.com/GPX/1/1">')
    ..writeln('  <metadata>')
    ..writeln('    <name>${_xmlEscape(name)}</name>')
    ..writeln('    <time>${startedAt.toUtc().toIso8601String()}</time>')
    ..writeln('  </metadata>')
    ..writeln('  <trk>')
    ..writeln('    <name>${_xmlEscape(name)}</name>')
    ..writeln('    <trkseg>');
  for (final p in points) {
    final time =
        DateTime.fromMillisecondsSinceEpoch(p.tMs).toUtc().toIso8601String();
    buffer.writeln('      <trkpt lat="${p.lat}" lon="${p.lng}">');
    if (p.altitude != null) buffer.writeln('        <ele>${p.altitude}</ele>');
    buffer.writeln('        <time>$time</time>');
    buffer.writeln('      </trkpt>');
  }
  buffer
    ..writeln('    </trkseg>')
    ..writeln('  </trk>')
    ..writeln('</gpx>');
  return buffer.toString();
}

String _xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
