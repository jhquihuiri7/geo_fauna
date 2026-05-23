import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado del clima actual de Open-Meteo, ya interpretado para la UI.
class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.isDay,
    required this.weatherCode,
  });

  final double temperature; // °C
  final double apparentTemperature; // °C
  final int humidity; // %
  final double windSpeed; // km/h
  final bool isDay;
  final int weatherCode; // código WMO

  String get emoji => _wmoEmoji(weatherCode, isDay);
  String get description => _wmoDescription(weatherCode);

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    return CurrentWeather(
      temperature: (c['temperature_2m'] as num).toDouble(),
      apparentTemperature: (c['apparent_temperature'] as num).toDouble(),
      humidity: (c['relative_humidity_2m'] as num).round(),
      windSpeed: (c['wind_speed_10m'] as num).toDouble(),
      isDay: (c['is_day'] as num) == 1,
      weatherCode: (c['weather_code'] as num).toInt(),
    );
  }
}

class WeatherService {
  /// Consulta el clima actual para una latitud/longitud dadas.
  Future<CurrentWeather> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,'
      'pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,'
      'wind_gusts_10m'
      '&temperature_unit=celsius&wind_speed_unit=kmh'
      '&precipitation_unit=mm&timezone=auto',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Open-Meteo respondió ${res.statusCode}');
    }
    return CurrentWeather.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
}

// ── Interpretación de códigos WMO ─────────────────────────────────────────────

String _wmoEmoji(int code, bool isDay) {
  if (code == 0) return isDay ? '☀️' : '🌙';
  if (code <= 2) return isDay ? '🌤️' : '☁️';
  if (code == 3) return '☁️';
  if (code == 45 || code == 48) return '🌫️';
  if (code >= 51 && code <= 57) return '🌦️';
  if (code >= 61 && code <= 67) return '🌧️';
  if (code >= 71 && code <= 77) return '🌨️';
  if (code >= 80 && code <= 82) return '🌧️';
  if (code >= 85 && code <= 86) return '🌨️';
  if (code >= 95) return '⛈️';
  return '🌡️';
}

String _wmoDescription(int code) {
  switch (code) {
    case 0:
      return 'Despejado';
    case 1:
      return 'Mayormente despejado';
    case 2:
      return 'Parcialmente nublado';
    case 3:
      return 'Nublado';
    case 45:
    case 48:
      return 'Niebla';
    case 51:
    case 53:
    case 55:
      return 'Llovizna';
    case 56:
    case 57:
      return 'Llovizna helada';
    case 61:
    case 63:
    case 65:
      return 'Lluvia';
    case 66:
    case 67:
      return 'Lluvia helada';
    case 71:
    case 73:
    case 75:
    case 77:
      return 'Nieve';
    case 80:
    case 81:
    case 82:
      return 'Chubascos';
    case 85:
    case 86:
      return 'Chubascos de nieve';
    case 95:
      return 'Tormenta';
    case 96:
    case 99:
      return 'Tormenta con granizo';
    default:
      return 'Indeterminado';
  }
}
