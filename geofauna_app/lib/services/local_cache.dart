import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_log.dart';

const _log = AppLog('CACHE');

/// Caché JSON en disco para el último dato bueno de un flujo (ubicación,
/// clima, marino).
///
/// Existe porque aquí la red se cae cada pocos minutos: sin esto, un arranque
/// en frío durante un corte deja la tarjeta sin absolutamente nada que mostrar.
///
/// Nunca lanza hacia fuera. Un caché corrupto o un disco lleno degradan la
/// experiencia, pero no deben tumbar la pantalla que los usa.
class LocalCache {
  const LocalCache(this.name);

  /// Identifica el archivo (`cache_<name>.json`) dentro del directorio de la
  /// app, el mismo sitio donde `OfflineSyncService` guarda su cola.
  final String name;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}cache_$name.json');
  }

  Future<Map<String, dynamic>?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (error) {
      _log.failure('no se pudo leer $name', error);
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> value) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(value));
    } catch (error) {
      _log.failure('no se pudo escribir $name', error);
    }
  }
}

/// Milisegundos desde época, tal y como los guardamos en el caché.
int nowMs() => DateTime.now().millisecondsSinceEpoch;

int? intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? doubleValueOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Cuerpo de respuesta recuperado del disco, con la hora en que se guardó.
class CachedBody {
  const CachedBody(this.body, this.savedAt);

  final String body;
  final DateTime savedAt;
}

/// Guarda el cuerpo crudo de una respuesta junto a dónde y cuándo se pidió.
///
/// Se guarda el JSON tal cual y no el objeto ya parseado: así el caché no se
/// invalida cada vez que cambie un modelo, y volver a leerlo es exactamente el
/// mismo camino que ya se recorre con la respuesta de red.
Future<void> writeCachedBody(
  LocalCache cache, {
  required double latitude,
  required double longitude,
  required String body,
}) {
  return cache.write({
    'latitude': latitude,
    'longitude': longitude,
    'savedAtMs': nowMs(),
    'body': body,
  });
}

/// Recupera el último cuerpo guardado, si se pidió lo bastante cerca de aquí.
///
/// El radio por defecto es generoso a propósito: Open-Meteo devuelve la misma
/// celda de malla para toda una zona, así que un pronóstico pedido a 10 km da
/// los mismos números.
Future<CachedBody?> readCachedBody(
  LocalCache cache, {
  required double latitude,
  required double longitude,
  double withinMeters = 10000,
}) async {
  final raw = await cache.read();
  if (raw == null) return null;

  final lat = doubleValueOrNull(raw['latitude']);
  final lon = doubleValueOrNull(raw['longitude']);
  final savedAtMs = intValue(raw['savedAtMs']);
  final body = raw['body'];
  if (lat == null || lon == null || savedAtMs == null || body is! String) {
    return null;
  }
  if (metersBetween(lat, lon, latitude, longitude) > withinMeters) return null;

  return CachedBody(body, DateTime.fromMillisecondsSinceEpoch(savedAtMs));
}

/// Distancia aproximada en metros entre dos coordenadas (haversine).
///
/// Propia y no la de geolocator para que la capa de caché no dependa del GPS:
/// también la usan flujos que solo manejan coordenadas guardadas.
double metersBetween(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double degrees) => degrees * math.pi / 180;
