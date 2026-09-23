import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'app_log.dart';
import 'failures.dart';
import 'local_cache.dart';

const _log = AppLog('LOC');

/// Cuánto esperamos un fix del GPS antes de conformarnos con la última
/// posición conocida.
///
/// Sin este límite `getCurrentPosition` puede no volver nunca —bajo techo, con
/// el chip frío— y la pantalla se queda en "Localizando…" para siempre, sin
/// error y sin datos. Era el peor de los síntomas porque no deja ni reintentar.
const Duration _gpsTimeout = Duration(seconds: 12);

/// El reverse-geocoding de Android tira de red, así que también se puede
/// colgar cuando el DNS no resuelve.
const Duration _geocodeTimeout = Duration(seconds: 8);

/// Radio dentro del cual damos por bueno el nombre de lugar guardado.
///
/// Puerto Baquerizo Moreno entero cabe de sobra en 3 km: si el geocoder no
/// responde, enseñar el nombre de la última vez es mucho mejor que caer a unas
/// coordenadas crudas que al usuario no le dicen nada.
const double _reuseNameMeters = 3000;

/// Último nombre de lugar resuelto con éxito, para sobrevivir a los cortes.
const _nameCache = LocalCache('place_name');

/// Ubicación resuelta: coordenadas + nombre legible del lugar.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.locality,
    this.area,
    this.resolvedOffline = false,
  });

  final double latitude;
  final double longitude;

  /// Ciudad / población (ej. "Puerto Ayora").
  final String? locality;

  /// Zona administrativa / región (ej. "Galápagos").
  final String? area;

  /// El nombre salió del caché en disco y no del geocoder: las coordenadas son
  /// de ahora, el nombre es el de la última vez que hubo red.
  final bool resolvedOffline;

  /// Línea principal para el encabezado (ej. "Puerto Ayora").
  String get title => locality ?? area ?? 'Ubicación actual';

  /// Línea secundaria (ej. "Galápagos · Ecuador").
  String? get subtitle {
    if (locality != null && area != null && locality != area) return area;
    return null;
  }
}

class LocationService {
  /// Solicita permisos, obtiene la posición y la convierte a nombre de lugar.
  /// Lanza [AppFailure] con mensaje claro si no es posible.
  Future<UserLocation> getCurrentLocation() async {
    final trace = _log.trace('getCurrentLocation');
    try {
      await _ensureReady(trace);
      final pos = await _position(trace);
      final resolved = await resolveLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      trace.done();
      return resolved;
    } catch (error) {
      trace.failed(error);
      rethrow;
    }
  }

  /// Convierte coordenadas arbitrarias (p. ej. un punto elegido en el mapa) en
  /// un [UserLocation] con nombre de lugar legible. No pide permisos ni usa el
  /// GPS, así que sirve para resolver una ubicación personalizada.
  Future<UserLocation> resolveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final trace = _log.trace('resolveLocation');
    trace.note('coordenadas $latitude, $longitude');

    String? locality;
    String? area;
    try {
      final placemarks = await trace.step(
        'placemarkFromCoordinates',
        () => placemarkFromCoordinates(
          latitude,
          longitude,
        ).timeout(_geocodeTimeout),
        describe: (list) => '${list.length} resultado(s)',
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        locality = (p.locality?.isNotEmpty ?? false)
            ? p.locality
            : (p.subAdministrativeArea?.isNotEmpty ?? false)
            ? p.subAdministrativeArea
            : null;
        area = (p.administrativeArea?.isNotEmpty ?? false)
            ? p.administrativeArea
            : p.country;
      } else {
        trace.note('sin placemarks');
      }
    } catch (error) {
      // El reverse-geocoding puede fallar sin red; seguimos sin relanzar.
      // No se pierde: el step de arriba ya dejó el stack en el log.
      trace.note('reverse-geocoding falló ($error)');
    }

    var resolvedOffline = false;
    if (locality == null && area == null) {
      // Sin nombre nuevo, el de la última vez es mejor que unas coordenadas.
      final cached = await _cachedName(latitude, longitude, trace);
      if (cached != null) {
        locality = cached.locality;
        area = cached.area;
        resolvedOffline = true;
      }
    } else {
      unawaited(_saveName(latitude, longitude, locality, area));
    }

    trace.note(
      'resultado locality=$locality area=$area'
      '${resolvedOffline ? ' (de caché)' : ''}',
    );
    trace.done();
    return UserLocation(
      latitude: latitude,
      longitude: longitude,
      locality: locality,
      area: area,
      resolvedOffline: resolvedOffline,
    );
  }

  /// Garantiza que tenemos permiso y el GPS encendido antes de grabar un
  /// recorrido. Lanza [AppFailure] con mensaje claro si no es posible, igual
  /// que [getCurrentLocation], para que la UI lo muestre tal cual.
  Future<void> ensureTrackingPermission() async {
    final trace = _log.trace('ensureTrackingPermission');
    try {
      await _ensureReady(trace);
      trace.done();
    } catch (error) {
      trace.failed(error);
      rethrow;
    }
  }

  /// GPS encendido + permiso concedido. Compartido por el encabezado del clima
  /// y por el tracking, que exigen exactamente lo mismo.
  Future<void> _ensureReady(LogTrace trace) async {
    final serviceEnabled = await trace.step(
      'isLocationServiceEnabled',
      Geolocator.isLocationServiceEnabled,
      describe: (on) => on ? 'GPS encendido' : 'GPS apagado',
    );
    if (!serviceEnabled) {
      throw const AppFailure(
        FailureKind.gpsOff,
        'Activa la ubicación (GPS) del dispositivo.',
      );
    }

    var permission = await trace.step(
      'checkPermission',
      Geolocator.checkPermission,
      describe: (p) => p.name,
    );
    if (permission == LocationPermission.denied) {
      // Este paso abre el diálogo del sistema: si se queda pendiente, es que
      // el usuario lo tiene delante sin responder.
      permission = await trace.step(
        'requestPermission (diálogo del sistema)',
        Geolocator.requestPermission,
        describe: (p) => p.name,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const AppFailure(
        FailureKind.permissionDenied,
        'Permiso de ubicación denegado.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppFailure(
        FailureKind.permissionBlocked,
        'Permiso de ubicación bloqueado. Actívalo en Ajustes.',
      );
    }
  }

  /// Pide un fix con límite de tiempo y, si no llega, se conforma con la última
  /// posición que el sistema ya tenía guardada.
  ///
  /// Nadie se mueve kilómetros entre dos arranques de la app, así que una
  /// posición de hace unos minutos da el mismo clima y el mismo nombre de
  /// puerto que una recién medida. Rendirse sería mucho peor que aproximar.
  Future<Position> _position(LogTrace trace) async {
    try {
      return await trace.step(
        'getCurrentPosition',
        () => Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: _gpsTimeout,
          ),
        ),
        describe: (p) =>
            '${p.latitude}, ${p.longitude} '
            '(±${p.accuracy.round()}m, fuente: ${p.isMocked ? 'simulada' : 'real'})',
      );
    } catch (error) {
      trace.note('sin fix nuevo; se prueba la última posición conocida');
      final last = await trace.step(
        'getLastKnownPosition',
        Geolocator.getLastKnownPosition,
        describe: (p) =>
            p == null ? 'sin posición previa' : '${p.latitude}, ${p.longitude}',
      );
      if (last != null) return last;

      if (error is TimeoutException) {
        throw AppFailure(
          FailureKind.noFix,
          'El GPS no encontró señal. Sal a cielo abierto e inténtalo de nuevo.',
          cause: error,
        );
      }
      rethrow;
    }
  }

  /// Flujo continuo de posiciones de alta precisión para grabar el recorrido.
  ///
  /// En Android se levanta un *foreground service* (notificación persistente)
  /// para que el SO no mate la grabación con la pantalla apagada o la app en
  /// segundo plano. En iOS se habilitan las actualizaciones en background.
  /// [distanceFilterMeters] descarta micro-movimientos por ruido del GPS.
  Stream<Position> trackPositionStream({int distanceFilterMeters = 8}) {
    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Recorrido en curso',
          notificationText: 'GeoFauna está registrando tu ruta de campo.',
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilterMeters,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}

/// Nombre de lugar guardado en disco junto a las coordenadas donde se resolvió.
class _CachedName {
  const _CachedName(this.locality, this.area);

  final String? locality;
  final String? area;
}

Future<_CachedName?> _cachedName(
  double latitude,
  double longitude,
  LogTrace trace,
) async {
  final raw = await _nameCache.read();
  if (raw == null) return null;

  final lat = doubleValueOrNull(raw['latitude']);
  final lon = doubleValueOrNull(raw['longitude']);
  if (lat == null || lon == null) return null;

  final meters = Geolocator.distanceBetween(lat, lon, latitude, longitude);
  if (meters > _reuseNameMeters) {
    trace.note('caché descartado: está a ${meters.round()}m de aquí');
    return null;
  }

  final locality = raw['locality'] as String?;
  final area = raw['area'] as String?;
  if (locality == null && area == null) return null;

  trace.note('nombre reusado del caché (a ${meters.round()}m)');
  return _CachedName(locality, area);
}

Future<void> _saveName(
  double latitude,
  double longitude,
  String? locality,
  String? area,
) {
  return _nameCache.write({
    'latitude': latitude,
    'longitude': longitude,
    'locality': locality,
    'area': area,
    'savedAtMs': nowMs(),
  });
}

/// Abre los ajustes de la app.
///
/// Es la única salida cuando el permiso quedó en `deniedForever`: a partir de
/// ahí el diálogo del sistema ya no se puede volver a mostrar, y sin esto el
/// usuario tendría que encontrar el camino en Ajustes por su cuenta.
Future<void> openLocationSettings() => Geolocator.openAppSettings();
