import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum TideState { rising, falling, highTide, lowTide }

class TideInfo {
  const TideInfo({required this.state, required this.seaLevelHeight});

  final TideState state;
  final double seaLevelHeight;

  String get label => switch (state) {
    TideState.rising   => 'SUBIENDO',
    TideState.falling  => 'BAJANDO',
    TideState.highTide => 'PLEAMAR',
    TideState.lowTide  => 'BAJAMAR',
  };

  String get arrow => switch (state) {
    TideState.rising   => '↑',
    TideState.falling  => '↓',
    TideState.highTide => '▲',
    TideState.lowTide  => '▼',
  };

  String get heightLabel {
    final sign = seaLevelHeight >= 0 ? '+' : '';
    return '$sign${seaLevelHeight.toStringAsFixed(2)} M';
  }
}

class WaveHour {
  const WaveHour({
    required this.time,
    required this.waveHeight,
    required this.waveDirection,
    required this.wavePeriod,
    required this.swellWaveHeight,
    required this.windWaveHeight,
    this.seaSurfaceTemperature,
    this.seaLevelHeight,
  });

  final DateTime time;
  final double waveHeight;
  final double waveDirection;
  final double wavePeriod;
  final double swellWaveHeight;
  final double windWaveHeight;
  final double? seaSurfaceTemperature;
  final double? seaLevelHeight;

  String get waveCondition => _waveCondition(waveHeight);
  String get directionLabel => _compassDirection(waveDirection);

  factory WaveHour.fromHourly(Map<String, dynamic> hourly, int index) {
    return WaveHour(
      time: _dateAt(hourly, 'time', index) ?? DateTime.now(),
      waveHeight: _doubleAt(hourly, 'wave_height', index),
      waveDirection: _doubleAt(hourly, 'wave_direction', index),
      wavePeriod: _doubleAt(hourly, 'wave_period', index),
      swellWaveHeight: _doubleAt(hourly, 'swell_wave_height', index),
      windWaveHeight: _doubleAt(hourly, 'wind_wave_height', index),
      seaSurfaceTemperature: _nullableDoubleAt(hourly, 'sea_surface_temperature', index),
      seaLevelHeight: _nullableDoubleAt(hourly, 'sea_level_height_msl', index),
    );
  }
}

class MarineForecast {
  const MarineForecast({required this.hourly});

  final List<WaveHour> hourly;

  factory MarineForecast.fromJson(Map<String, dynamic> json) {
    final hourlyData = json['hourly'] is Map<String, dynamic>
        ? json['hourly'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final times = hourlyData['time'] is List ? hourlyData['time'] as List : [];
    final hourly = [
      for (var i = 0; i < times.length; i++) WaveHour.fromHourly(hourlyData, i),
    ];
    return MarineForecast(hourly: hourly);
  }

  List<WaveHour> hoursForDay(DateTime date) {
    return [
      for (final wave in hourly)
        if (_sameDay(wave.time, date)) wave,
    ];
  }

  WaveHour? atHour(DateTime dateTime) {
    WaveHour? best;
    var bestDiff = double.maxFinite.toInt();
    for (final wave in hourly) {
      final diff = wave.time.difference(dateTime).inMinutes.abs();
      if (diff < bestDiff) {
        best = wave;
        bestDiff = diff;
      }
    }
    return best;
  }

  /// Compara la hora actual con la anterior y la siguiente para determinar
  /// si la marea está subiendo, bajando, o en pico/valle.
  TideInfo? tideAt(DateTime time) {
    if (hourly.length < 3) return null;

    var idx = 0;
    var bestDiff = hourly[0].time.difference(time).inMinutes.abs();
    for (var i = 1; i < hourly.length; i++) {
      final diff = hourly[i].time.difference(time).inMinutes.abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        idx = i;
      }
    }

    if (idx == 0 || idx >= hourly.length - 1) return null;

    final curr = hourly[idx].seaLevelHeight;
    final prev = hourly[idx - 1].seaLevelHeight;
    final next = hourly[idx + 1].seaLevelHeight;
    if (curr == null || prev == null || next == null) return null;

    final TideState state;
    if (curr > prev && curr > next) {
      state = TideState.highTide;
    } else if (curr < prev && curr < next) {
      state = TideState.lowTide;
    } else if (curr >= prev) {
      state = TideState.rising;
    } else {
      state = TideState.falling;
    }

    return TideInfo(state: state, seaLevelHeight: curr);
  }

  double maxWaveHeightForDay(DateTime date) {
    final hours = hoursForDay(date);
    if (hours.isEmpty) return 0;
    return hours.map((h) => h.waveHeight).reduce((a, b) => a > b ? a : b);
  }
}

class MarineService {
  Future<MarineForecast> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'marine-api.open-meteo.com',
      '/v1/marine',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'hourly': 'wave_height,wave_direction,wave_period,swell_wave_height,'
            'wind_wave_height,sea_surface_temperature,sea_level_height_msl',
        'timezone': 'auto',
        'forecast_days': '8',
      },
    );

    debugPrint('🌊 Marine request: ${uri.toString()}');
    final res = await http.get(uri);
    debugPrint('🌊 Marine response: ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('Open-Meteo Marine respondio ${res.statusCode} - ${res.body}');
    }

    return MarineForecast.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}

DateTime? _dateAt(Map<String, dynamic> json, String key, int index) {
  final values = json[key];
  if (values is! List || index >= values.length) return null;
  final value = values[index];
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double _doubleAt(Map<String, dynamic> json, String key, int index) {
  final values = json[key];
  if (values is! List || index >= values.length) return 0;
  final value = values[index];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

double? _nullableDoubleAt(Map<String, dynamic> json, String key, int index) {
  final values = json[key];
  if (values is! List || index >= values.length) return null;
  final value = values[index];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _waveCondition(double height) {
  if (height < 0.5) return 'Calma';
  if (height < 1.25) return 'Ligero';
  if (height < 2.5) return 'Moderado';
  if (height < 4.0) return 'Agitado';
  if (height < 6.0) return 'Bravo';
  return 'Muy bravo';
}

String _compassDirection(double degrees) {
  const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
  return dirs[((degrees + 22.5) / 45).floor() % 8];
}
