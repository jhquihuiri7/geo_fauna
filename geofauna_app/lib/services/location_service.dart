import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'app_log.dart';

const _log = AppLog('LOC');

/// Ubicación resuelta: coordenadas + nombre legible del lugar.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.locality,
    this.area,
  });

  final double latitude;
  final double longitude;

  /// Ciudad / población (ej. "Puerto Ayora").
  final String? locality;

  /// Zona administrativa / región (ej. "Galápagos").
  final String? area;

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
  /// Lanza una excepción con mensaje claro si no es posible.
  Future<UserLocation> getCurrentLocation() async {
    final trace = _log.trace('getCurrentLocation');
    try {
      final serviceEnabled = await trace.step(
        'isLocationServiceEnabled',
        Geolocator.isLocationServiceEnabled,
        describe: (on) => on ? 'GPS encendido' : 'GPS apagado',
      );
      if (!serviceEnabled) {
        throw Exception('Activa la ubicación (GPS) del dispositivo.');
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
        throw Exception('Permiso de ubicación denegado.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación bloqueado. Actívalo en Ajustes.');
      }

      final pos = await trace.step(
        'getCurrentPosition',
        () => Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ),
        describe: (p) =>
            '${p.latitude}, ${p.longitude} '
            '(±${p.accuracy.round()}m, fuente: ${p.isMocked ? 'simulada' : 'real'})',
      );

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
        () => placemarkFromCoordinates(latitude, longitude),
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
        trace.note('sin placemarks; se mostrarán las coordenadas');
      }
    } catch (error) {
      // El reverse-geocoding puede fallar sin red; seguimos con coordenadas.
      // No se relanza, pero ya no se pierde: el step de arriba dejó el stack.
      trace.note('reverse-geocoding falló ($error); se sigue con coordenadas');
    }

    trace.note('resultado locality=$locality area=$area');
    trace.done();
    return UserLocation(
      latitude: latitude,
      longitude: longitude,
      locality: locality,
      area: area,
    );
  }

  /// Garantiza que tenemos permiso y el GPS encendido antes de grabar un
  /// recorrido. Lanza una excepción con mensaje claro si no es posible, igual
  /// que [getCurrentLocation], para que la UI lo muestre tal cual.
  Future<void> ensureTrackingPermission() async {
    final trace = _log.trace('ensureTrackingPermission');
    try {
      final serviceEnabled = await trace.step(
        'isLocationServiceEnabled',
        Geolocator.isLocationServiceEnabled,
        describe: (on) => on ? 'GPS encendido' : 'GPS apagado',
      );
      if (!serviceEnabled) {
        throw Exception('Activa la ubicación (GPS) del dispositivo.');
      }

      var permission = await trace.step(
        'checkPermission',
        Geolocator.checkPermission,
        describe: (p) => p.name,
      );
      if (permission == LocationPermission.denied) {
        permission = await trace.step(
          'requestPermission (diálogo del sistema)',
          Geolocator.requestPermission,
          describe: (p) => p.name,
        );
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación bloqueado. Actívalo en Ajustes.');
      }
      trace.done();
    } catch (error) {
      trace.failed(error);
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
