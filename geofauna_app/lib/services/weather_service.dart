import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.isDay,
    required this.weatherCode,
    required this.cloudCover,
    required this.rain,
    this.dayMinTemperature,
    this.dayMaxTemperature,
  });

  final DateTime time;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final bool isDay;
  final int weatherCode;
  final int cloudCover;
  final double rain;
  final double? dayMinTemperature;
  final double? dayMaxTemperature;

  String get emoji => _wmoEmoji(weatherCode, isDay);
  String get description => _wmoDescription(weatherCode);

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    return CurrentWeather(
      time: _dateValue(c['time']) ?? DateTime.now(),
      temperature: _doubleValue(c['temperature_2m']),
      humidity: _doubleValue(c['relative_humidity_2m']).round(),
      windSpeed: _doubleValue(c['wind_speed_10m']),
      isDay: _doubleValue(c['is_day']).round() == 1,
      weatherCode: _doubleValue(c['weather_code']).round(),
      cloudCover: _doubleValue(c['cloud_cover']).round(),
      rain: _doubleValue(c['rain']),
    );
  }

  factory CurrentWeather.fromHourly(Map<String, dynamic> hourly, int index) {
    final time = _dateAt(hourly, 'time', index) ?? DateTime.now();
    return CurrentWeather(
      time: time,
      temperature: _doubleAt(hourly, 'temperature_2m', index),
      humidity: _doubleAt(hourly, 'relative_humidity_2m', index).round(),
      windSpeed: _doubleAt(hourly, 'wind_speed_10m', index),
      isDay: _isDayHour(time),
      weatherCode: _doubleAt(hourly, 'weather_code', index).round(),
      cloudCover: _doubleAt(hourly, 'cloud_cover', index).round(),
      rain: _doubleAt(hourly, 'rain', index),
    );
  }

  CurrentWeather withDailyRange(WeatherDayRange? range) {
    return CurrentWeather(
      time: time,
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      isDay: isDay,
      weatherCode: weatherCode,
      cloudCover: cloudCover,
      rain: rain,
      dayMinTemperature: range?.minTemperature,
      dayMaxTemperature: range?.maxTemperature,
    );
  }
}

class WeatherDayRange {
  const WeatherDayRange({
    required this.minTemperature,
    required this.maxTemperature,
  });

  final double minTemperature;
  final double maxTemperature;
}

class WeatherForecast {
  const WeatherForecast({required this.current, required this.hourly});

  final CurrentWeather current;
  final List<CurrentWeather> hourly;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final hourlyData = json['hourly'] is Map<String, dynamic>
        ? json['hourly'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final times = hourlyData['time'] is List ? hourlyData['time'] as List : [];
    final hourly = [
      for (var i = 0; i < times.length; i++)
        CurrentWeather.fromHourly(hourlyData, i),
    ];

    final rawCurrent = CurrentWeather.fromJson(json);
    final current = rawCurrent.withDailyRange(
      _rangeForDay(hourly, rawCurrent.time),
    );

    return WeatherForecast(current: current, hourly: hourly);
  }

  CurrentWeather? atPhoneHour(DateTime date) {
    final hours = hoursForDay(date);
    if (hours.isEmpty) return null;

    final phoneHour = DateTime.now().hour;
    CurrentWeather selected = hours.first;
    var bestDistance = (selected.time.hour - phoneHour).abs();

    for (final weather in hours.skip(1)) {
      final distance = (weather.time.hour - phoneHour).abs();
      if (distance < bestDistance) {
        selected = weather;
        bestDistance = distance;
      }
    }

    return selected.withDailyRange(_rangeForHours(hours));
  }

  List<CurrentWeather> hoursForDay(DateTime date) {
    final range = _rangeForDay(hourly, date);
    return [
      for (final weather in hourly)
        if (_sameDay(weather.time, date)) weather.withDailyRange(range),
    ];
  }
}

class WeatherService {
  Future<CurrentWeather> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    return (await fetchForecast(
      latitude: latitude,
      longitude: longitude,
    )).current;
  }

  Future<WeatherForecast> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,is_day,rain,weather_code,cloud_cover,wind_speed_10m',
        'hourly': 'temperature_2m,relative_humidity_2m,rain,weather_code,cloud_cover,wind_speed_10m',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
        'timezone': 'auto',
        'forecast_days': '15',
      },
    );

    debugPrint('🌤️ Weather request: ${uri.toString()}');
    final res = await http.get(uri);
    debugPrint('🌤️ Weather response: ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Open-Meteo respondio ${res.statusCode} - ${res.body}');
    }

    return WeatherForecast.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}

WeatherDayRange? _rangeForDay(List<CurrentWeather> hourly, DateTime date) {
  return _rangeForHours([
    for (final weather in hourly)
      if (_sameDay(weather.time, date)) weather,
  ]);
}

WeatherDayRange? _rangeForHours(List<CurrentWeather> hours) {
  if (hours.isEmpty) return null;

  var min = hours.first.temperature;
  var max = hours.first.temperature;
  for (final weather in hours.skip(1)) {
    if (weather.temperature < min) min = weather.temperature;
    if (weather.temperature > max) max = weather.temperature;
  }
  return WeatherDayRange(minTemperature: min, maxTemperature: max);
}

DateTime? _dateAt(Map<String, dynamic> json, String key, int index) {
  final values = json[key];
  if (values is! List || index >= values.length) return null;
  return _dateValue(values[index]);
}

double _doubleAt(Map<String, dynamic> json, String key, int index) {
  final values = json[key];
  if (values is! List || index >= values.length) return 0;
  return _doubleValue(values[index]);
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isDayHour(DateTime time) {
  return time.hour >= 6 && time.hour < 18;
}

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
