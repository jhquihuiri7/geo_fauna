import 'dart:async';

import 'package:flutter/material.dart';

import '../services/failures.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/weather_store.dart';
import '../theme/app_colors.dart';
import 'eco_widgets.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// Suscribe a [WeatherStore] y reconstruye mediante [builder] cada vez que la
/// ubicación o el clima cambian.
///
/// Antes cada instancia guardaba su propio `Future` en un campo `static`, lo
/// que congelaba el primer fallo para toda la vida del proceso y hacía que
/// "Reintentar" en el Dashboard no arreglara la Agenda. Ahora el estado vive
/// en un solo sitio y todas las tarjetas lo ven a la vez.
class WeatherBuilder extends StatefulWidget {
  const WeatherBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, WeatherStore store) builder;

  @override
  State<WeatherBuilder> createState() => _WeatherBuilderState();
}

class _WeatherBuilderState extends State<WeatherBuilder> {
  final WeatherStore _store = WeatherStore.instance;

  @override
  void initState() {
    super.initState();
    // El store deduplica: si la otra pantalla ya lo pidió, esto no dispara una
    // segunda petición de GPS.
    unawaited(_store.ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => widget.builder(context, _store),
    );
  }
}

/// Fila de error compartida por el encabezado y la tarjeta de la agenda: el
/// mismo fallo se ve igual en las dos pantallas.
Widget _errorRow(AppColors eco, Object error, VoidCallback retry) {
  final hint = weatherErrorHint(error);
  return Row(
    children: [
      Icon(weatherErrorIcon(error), size: 26, color: eco.onSurfaceVariant),
      const SizedBox(width: AppSpacing.space3_5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weatherErrorMessage(error),
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: eco.onSurfaceVariant,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(fontSize: 11, height: 1.3, color: eco.outline),
              ),
            ],
          ],
        ),
      ),
      if (failureKindOf(error) == FailureKind.permissionBlocked)
        TextButton(
          onPressed: () => unawaited(openLocationSettings()),
          child: const Text('Ajustes'),
        )
      else
        TextButton(onPressed: retry, child: const Text('Reintentar')),
    ],
  );
}

/// Aviso de que lo que se ve es el último dato guardado y no el de ahora.
/// Sin esto, un clima de hace horas se confunde con uno recién pedido.
Widget _staleBadge(AppColors eco, String age) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.cloud_off_rounded, size: 11, color: eco.warning),
      const SizedBox(width: AppSpacing.space1),
      Text(
        'SIN CONEXIÓN · $age',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: eco.warning,
        ),
      ),
    ],
  );
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
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.space2,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: eco.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: eco.primary),
        const SizedBox(width: AppSpacing.space1),
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
///
/// Los [AppFailure] traen su texto ya redactado; el resto cae al genérico.
String weatherErrorMessage(Object error) {
  final s = error.toString();
  return s.startsWith('Exception: ')
      ? s.substring(11)
      : 'No se pudo obtener el clima.';
}

/// Qué puede hacer el usuario ante este error, en una línea.
///
/// El mensaje dice qué pasó; esto dice qué hacer, que es distinto en cada
/// caso: encender el GPS, abrir Ajustes o simplemente esperar a la señal.
String? weatherErrorHint(Object error) => switch (failureKindOf(error)) {
  FailureKind.gpsOff => 'Actívala en los ajustes rápidos del teléfono.',
  FailureKind.permissionBlocked =>
    'Android ya no deja preguntarlo desde la app.',
  FailureKind.network => 'Se reintenta solo en cuanto vuelva la señal.',
  FailureKind.noFix => 'A cielo abierto el GPS fija la posición antes.',
  _ => null,
};

/// Icono acorde al tipo de fallo, para distinguirlo de un vistazo.
IconData weatherErrorIcon(Object error) => switch (failureKindOf(error)) {
  FailureKind.network => Icons.wifi_off_rounded,
  FailureKind.gpsOff || FailureKind.noFix => Icons.location_disabled_rounded,
  FailureKind.permissionDenied ||
  FailureKind.permissionBlocked => Icons.lock_outline_rounded,
  _ => Icons.error_outline_rounded,
};

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard — encabezado "Estado del Tiempo"
// ─────────────────────────────────────────────────────────────────────────────

class WeatherHeader extends StatelessWidget {
  const WeatherHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return WeatherBuilder(
      builder: (context, store) {
        final snap = store.snapshot;
        // La ubicación se publica antes que el clima, así que el nombre del
        // puerto aparece aunque Open-Meteo siga sin contestar.
        final location = snap.data?.location ?? store.location;

        final String title;
        final String subtitle;
        if (location != null) {
          title = location.title;
          subtitle =
              location.subtitle ??
              '${location.latitude.toStringAsFixed(2)}, '
                  '${location.longitude.toStringAsFixed(2)}';
        } else {
          title = snap.hasError ? 'Sin ubicación' : 'Localizando…';
          subtitle = 'Obteniendo tu posición actual';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTADO DEL TIEMPO',
              style: AppTextStyles.eyebrow.copyWith(color: eco.primary),
            ),
            const SizedBox(height: AppSpacing.space1),
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
                    style: AppTextStyles.body.copyWith(
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            _card(context, eco, snap, store.refresh),
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
    if (snap.hasError) {
      return EcoCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4_5,
          vertical: AppSpacing.space4,
        ),
        child: _errorRow(eco, snap.error!, retry),
      );
    }

    if (!snap.hasData) {
      return EcoCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4_5,
          vertical: AppSpacing.space3_5,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.space7,
              height: AppSpacing.space7,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: eco.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
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

    final data = snap.data!;
    final w = data.weather;
    final now = DateTime.now();
    final wave = data.marineForecast?.atHour(now);
    final tide = data.marineForecast?.tideAt(now);
    final age = data.ageLabel;
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4_5,
        vertical: AppSpacing.space3_5,
      ),
      child: Row(
        children: [
          Text(w.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.space4),
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
                const SizedBox(height: AppSpacing.space1),
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
                const SizedBox(height: AppSpacing.space2),
                _weatherMetrics(eco, w),
                if (age != null) ...[
                  const SizedBox(height: 6),
                  _staleBadge(eco, age),
                ],
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
      builder: (context, store) {
        final snap = store.snapshot;
        return GestureDetector(
          onTap: snap.hasData
              ? () => _openHourlySheet(context, snap.data!)
              : null,
          behavior: HitTestBehavior.opaque,
          child: EcoCard(
            radius: 32,
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: AppSpacing.space5,
            ),
            child: _content(eco, snap, store.refresh),
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
    if (snap.hasError) {
      return _errorRow(eco, snap.error!, retry);
    }

    if (!snap.hasData) {
      return Row(
        children: [
          SizedBox(
            width: AppSpacing.space7,
            height: AppSpacing.space7,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: eco.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
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
    final age = data.ageLabel;
    final w = data.forecast.atPhoneHour(selectedDate);
    if (w == null) {
      return Row(
        children: [
          Icon(Icons.cloud_off, color: eco.outline),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              'No hay pronostico disponible para esta fecha.',
              style: AppTextStyles.bodySm.copyWith(color: eco.onSurfaceVariant),
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
                      style: AppTextStyles.bodyStrong.copyWith(
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
                  const SizedBox(width: AppSpacing.space2),
                  Flexible(
                    child: Text(
                      w.description,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: eco.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Row(
                children: [
                  _stat(eco, Icons.water_drop, '${w.humidity}% HUM.'),
                  const SizedBox(width: AppSpacing.space4),
                  _stat(eco, Icons.air, '${w.windSpeed.round()} KM/H'),
                ],
              ),
              const SizedBox(height: 10),
              _weatherMetrics(eco, w),
              if (age != null) ...[
                const SizedBox(height: 6),
                _staleBadge(eco, age),
              ],
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  Icon(Icons.touch_app, size: 13, color: eco.outline),
                  const SizedBox(width: AppSpacing.space1),
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
        const SizedBox(width: AppSpacing.space3),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space5,
                AppSpacing.space3,
                AppSpacing.space5,
                AppSpacing.space5,
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetEco.outlineVariant,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _weatherDateLabel(selectedDate),
                          style: AppTextStyles.titleMd.copyWith(
                            color: sheetEco.onSurface,
                          ),
                        ),
                      ),
                      EcoChip('${hours.length} horas', tone: ChipTone.slate),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
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
                  const SizedBox(height: AppSpacing.space3_5),
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
      padding: const EdgeInsets.all(AppSpacing.space3_5),
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
          const SizedBox(width: AppSpacing.space3),
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
                      style: AppTextStyles.titleLg.copyWith(
                        color: eco.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
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
                const SizedBox(height: AppSpacing.space2),
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
        const SizedBox(width: AppSpacing.space1),
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
