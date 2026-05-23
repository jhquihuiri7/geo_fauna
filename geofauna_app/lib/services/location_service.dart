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
}
