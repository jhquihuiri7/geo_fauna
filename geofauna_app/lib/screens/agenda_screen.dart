import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/user_avatar.dart';
import '../widgets/weather_header.dart';

/// Agenda — daily field logistics: weather, day strip, timeline (screens-main.jsx).
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  // Nombres en español (sin dependencia de intl).
  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
  ];
  static const _weekdayAbbr = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom' // 1=Lun … 7=Dom
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      color: eco.surface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          EcoTopBar(
            large: true,
            title: 'Mi Bitácora',
            leading: const UserAvatar(size: 40),
            trailing: [Icon(Icons.cloud_done, color: eco.primary)],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu Agenda',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -1.5,
                        color: eco.onSurface)),
                const SizedBox(height: 8),
                Text(
                    'Logística de campo para hoy, '
                    '${now.day} de ${_months[now.month - 1]}',
                    style:
                        TextStyle(fontSize: 15, color: eco.onSurfaceVariant)),
                const SizedBox(height: 24),
                const AgendaWeatherCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                for (var i = 0; i < 5; i++)
                  _dayCell(
                    eco,
                    i == 0
                        ? 'Hoy'
                        : _weekdayAbbr[
                            today.add(Duration(days: i)).weekday - 1],
                    today.add(Duration(days: i)).day,
                    i == 0,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _timeline(context, eco),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(AppColors eco, String day, int num, bool active) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: active ? eco.primaryContainer : eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: (active ? eco.onPrimaryContainer : eco.onSurface)
                      .withValues(alpha: 0.8))),
          const SizedBox(height: 4),
          Text('$num',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: active ? eco.onPrimaryContainer : eco.onSurface)),
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context, AppColors eco) {
    // Sin backend de actividades aún: estado vacío en lugar de eventos falsos.
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available, color: eco.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Sin actividades para hoy',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: eco.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Programa una expedición o evento desde la pestaña "Nuevo".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: eco.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
