import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import 'eco_widgets.dart';

/// Ubicación + clima actual ya resueltos.
class WeatherData {
  const WeatherData(this.location, this.weather);
  final UserLocation location;
  final CurrentWeather weather;
}

/// Obtiene una vez la ubicación del dispositivo + el clima actual y reconstruye
/// mediante [builder], al que entrega el snapshot y un callback `retry`.
/// Centraliza la lógica para que Dashboard y Agenda compartan la misma fuente.
class WeatherBuilder extends StatefulWidget {
  const WeatherBuilder({super.key, required this.builder});

  final Widget Function(
      BuildContext, AsyncSnapshot<WeatherData>, VoidCallback retry) builder;

  @override
  State<WeatherBuilder> createState() => _WeatherBuilderState();
}

class _WeatherBuilderState extends State<WeatherBuilder> {
  late Future<WeatherData> _future = _load();

  Future<WeatherData> _load() async {
    final loc = await LocationService().getCurrentLocation();
    final weather = await WeatherService().fetchCurrent(
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
    return WeatherData(loc, weather);
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherData>(
      future: _future,
      builder: (context, snap) => widget.builder(context, snap, _retry),
    );
  }
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
            Text('ESTADO DEL TIEMPO',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: eco.primary)),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1,
                    color: eco.onSurface)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: eco.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(subtitle,
                      style:
                          TextStyle(fontSize: 14, color: eco.onSurfaceVariant)),
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

  Widget _card(BuildContext context, AppColors eco,
      AsyncSnapshot<WeatherData> snap, VoidCallback retry) {
    if (snap.connectionState == ConnectionState.done && snap.hasError) {
      return EcoCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            const Text('📍', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(weatherErrorMessage(snap.error!),
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: eco.onSurfaceVariant)),
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
                  strokeWidth: 2.5, color: eco.primary),
            ),
            const SizedBox(width: 16),
            Text('Consultando el clima…',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: eco.onSurfaceVariant)),
          ],
        ),
      );
    }

    final w = snap.data!.weather;
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
                    Text('${w.temperature.round()}°C',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: eco.onSurface)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(w.description,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: eco.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'HUMEDAD ${w.humidity}% · '
                  'VIENTO ${w.windSpeed.round()} KM/H · '
                  'SENS. ${w.apparentTemperature.round()}°',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: eco.onSurfaceVariant),
                ),
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
  const AgendaWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return WeatherBuilder(
      builder: (context, snap, retry) {
        return EcoCard(
          radius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: _content(eco, snap, retry),
        );
      },
    );
  }

  Widget _content(AppColors eco, AsyncSnapshot<WeatherData> snap,
      VoidCallback retry) {
    if (snap.connectionState == ConnectionState.done && snap.hasError) {
      return Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(weatherErrorMessage(snap.error!),
                style: TextStyle(
                    fontSize: 13, height: 1.3, color: eco.onSurfaceVariant)),
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
            child:
                CircularProgressIndicator(strokeWidth: 2.5, color: eco.primary),
          ),
          const SizedBox(width: 16),
          Text('Consultando el clima…',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: eco.onSurfaceVariant)),
        ],
      );
    }

    final loc = snap.data!.location;
    final w = snap.data!.weather;
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
                    child: Text(loc.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: eco.onSurface)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${w.temperature.round()}°C',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: eco.onSurface)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(w.description,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14, color: eco.onSurfaceVariant)),
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

  Widget _stat(AppColors eco, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: eco.primary),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: eco.onSurfaceVariant)),
      ],
    );
  }
}
