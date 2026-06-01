import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/marine_service.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import 'eco_widgets.dart';

/// Ubicación + clima actual ya resueltos.
class WeatherData {
  const WeatherData(this.location, this.forecast, [this.marineForecast]);

  final UserLocation location;
  final WeatherForecast forecast;
  final MarineForecast? marineForecast;

  CurrentWeather get weather => forecast.current;
}

/// Obtiene una vez la ubicación del dispositivo + el clima actual y reconstruye
/// mediante [builder], al que entrega el snapshot y un callback `retry`.
/// Centraliza la lógica para que Dashboard y Agenda compartan la misma fuente.
class WeatherBuilder extends StatefulWidget {
  const WeatherBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext,
    AsyncSnapshot<WeatherData>,
    VoidCallback retry,
  )
  builder;

  @override
  State<WeatherBuilder> createState() => _WeatherBuilderState();
}

class _WeatherBuilderState extends State<WeatherBuilder> {
  static Future<WeatherData>? _cachedFuture;

  late Future<WeatherData> _future = _cachedFuture ??= _load();

  Future<WeatherData> _load() async {
    final loc = await LocationService().getCurrentLocation();
    final weatherFuture = WeatherService().fetchForecast(
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
    final marineFuture = (() async {
      try {
        return await MarineService().fetchForecast(
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      } catch (_) {
        return null;
      }
    })();
    final forecast = await weatherFuture;
    final marine = await marineFuture;
    return WeatherData(loc, forecast, marine);
  }

  void _retry() {
    setState(() {
      _cachedFuture = _load();
      _future = _cachedFuture!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherData>(
      future: _future,
      builder: (context, snap) => widget.builder(context, snap, _retry),
    );
  }
}

Widget _weatherMetrics(
  AppColors eco,
  CurrentWeather weather, {
  bool compact = false,
}) {
  final min = weather.dayMinTemperature;
  final max = weather.dayMaxTemperature;
  return Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      if (min != null && max != null)
        _metric(eco, Icons.thermostat, '${min.round()}-${max.round()}°C'),
      _metric(eco, Icons.water_drop, '${weather.humidity}% HUM'),
      _metric(eco, Icons.air, '${weather.windSpeed.round()} KM/H'),
      if (!compact) ...[
        _metric(eco, Icons.water, 'LLUV ${_oneDecimal(weather.rain)}'),
        _metric(eco, Icons.cloud, '${weather.cloudCover}% NUBES'),
      ] else ...[
        _metric(eco, Icons.cloud, '${weather.cloudCover}% NUBES'),
      ],
    ],
  );
}

Widget _metric(AppColors eco, IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: eco.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: eco.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: eco.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );
}

String _hourLabel(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:00';
}

String _weatherDateLabel(DateTime date) {
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]}';
}

String _oneDecimal(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

/// Mensaje de error legible a partir de una excepción.
String weatherErrorMessage(Object error) {
  final s = error.toString();
  return s.startsWith('Exception: ')
      ? s.substring(11)
      : 'No se pudo obtener el clima.';
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard — encabezado "Estado del Tiempo"
// ─────────────────────────────────────────────────────────────────────────────

class WeatherHeader extends StatelessWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return WeatherBuilder(
      builder: (context, snap, retry) {
        final title = switch (snap.connectionState) {
          ConnectionState.done when snap.hasData => snap.data!.location.title,
          ConnectionState.done => 'Sin ubicación',
          _ => 'Localizando…',
        };
        final subtitle = snap.hasData
            ? (snap.data!.location.subtitle ??
                  '${snap.data!.location.latitude.toStringAsFixed(2)}, '
                      '${snap.data!.location.longitude.toStringAsFixed(2)}')
            : 'Obteniendo tu posición actual';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTADO DEL TIEMPO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: eco.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                height: 1,
                color: eco.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: eco.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: eco.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _card(context, eco, snap, retry),
          ],
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    AppColors eco,
    AsyncSnapshot<WeatherData> snap,
    VoidCallback retry,
  ) {
    if (snap.connectionState == ConnectionState.done && snap.hasError) {
      return EcoCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                weatherErrorMessage(snap.error!),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: eco.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: retry, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (!snap.hasData) {
      return EcoCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: eco.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Consultando el clima…',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: eco.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final w = snap.data!.weather;
    final now = DateTime.now();
    final wave = snap.data!.marineForecast?.atHour(now);
    final tide = snap.data!.marineForecast?.tideAt(now);
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Text(w.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${w.temperature.round()}°C',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: eco.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        w.description,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'HUMEDAD ${w.humidity}% · '
                  'VIENTO ${w.windSpeed.round()} KM/H',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: eco.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _weatherMetrics(eco, w),
                if (wave != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'OLEAJE ${_oneDecimal(wave.waveHeight)} M  ·  '
                    'PER. ${wave.wavePeriod.round()}S  ·  '
                    '${wave.directionLabel}  ·  ${wave.waveCondition.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                ],
                if (tide != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'MAREA ${tide.arrow} ${tide.label}  ·  ${tide.heightLabel}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Agenda — tarjeta de clima (ubicación, temperatura, humedad, viento)
// ─────────────────────────────────────────────────────────────────────────────

class AgendaWeatherCard extends StatelessWidget {
  const AgendaWeatherCard({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return WeatherBuilder(
      builder: (context, snap, retry) {
        return GestureDetector(
          onTap: snap.hasData
              ? () => _openHourlySheet(context, snap.data!)
              : null,
          behavior: HitTestBehavior.opaque,
          child: EcoCard(
            radius: 32,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: _content(eco, snap, retry),
          ),
        );
      },
    );
  }

  Widget _content(
    AppColors eco,
    AsyncSnapshot<WeatherData> snap,
    VoidCallback retry,
  ) {
    if (snap.connectionState == ConnectionState.done && snap.hasError) {
      return Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              weatherErrorMessage(snap.error!),
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: eco.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: retry, child: const Text('Reintentar')),
        ],
      );
    }

    if (!snap.hasData) {
      return Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: eco.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Consultando el clima…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: eco.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final data = snap.data!;
    final loc = data.location;
    final w = data.forecast.atPhoneHour(selectedDate);
    if (w == null) {
      return Row(
        children: [
          Icon(Icons.cloud_off, color: eco.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay pronostico disponible para esta fecha.',
              style: TextStyle(fontSize: 13, color: eco.onSurfaceVariant),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: eco.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      loc.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${w.temperature.round()}°C',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: eco.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      w.description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: eco.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat(eco, Icons.water_drop, '${w.humidity}% HUM.'),
                  const SizedBox(width: 16),
                  _stat(eco, Icons.air, '${w.windSpeed.round()} KM/H'),
                ],
              ),
              const SizedBox(height: 10),
              _weatherMetrics(eco, w),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.touch_app, size: 13, color: eco.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Toca para ver todas las horas',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: eco.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: eco.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Text(w.emoji, style: const TextStyle(fontSize: 36)),
        ),
      ],
    );
  }

  void _openHourlySheet(BuildContext context, WeatherData data) {
    final hours = data.forecast.hoursForDay(selectedDate);
    final eco = context.eco;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: eco.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final sheetEco = context.eco;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetEco.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _weatherDateLabel(selectedDate),
                          style: TextStyle(
                            color: sheetEco.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      EcoChip('${hours.length} horas', tone: ChipTone.slate),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.location.title,
                      style: TextStyle(
                        color: sheetEco.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: hours.isEmpty
                        ? Center(
                            child: Text(
                              'No hay pronostico para este dia.',
                              style: TextStyle(
                                color: sheetEco.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: hours.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _hourRow(sheetEco, hours[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hourRow(AppColors eco, CurrentWeather weather) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Text(
                  _hourLabel(weather.time),
                  style: TextStyle(
                    color: eco.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(weather.emoji, style: const TextStyle(fontSize: 26)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${weather.temperature.round()}°C',
                      style: TextStyle(
                        color: eco.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weather.description,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: eco.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _weatherMetrics(eco, weather),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(AppColors eco, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: eco.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: eco.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
