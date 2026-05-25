import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Activa la ubicación (GPS) del dispositivo.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permiso de ubicación bloqueado. Actívalo en Ajustes.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    String? locality;
    String? area;
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
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
      }
    } catch (_) {
      // El reverse-geocoding puede fallar sin red; seguimos con coordenadas.
    }

    return UserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      locality: locality,
      area: area,
    );
  }

  /// Garantiza que tenemos permiso y el GPS encendido antes de grabar un
  /// recorrido. Lanza una excepción con mensaje claro si no es posible, igual
  /// que [getCurrentLocation], para que la UI lo muestre tal cual.
  Future<void> ensureTrackingPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Activa la ubicación (GPS) del dispositivo.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación bloqueado. Actívalo en Ajustes.');
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
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
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
