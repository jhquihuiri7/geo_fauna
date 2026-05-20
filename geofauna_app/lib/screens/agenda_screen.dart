import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';

/// Agenda — daily field logistics: weather, day strip, timeline (screens-main.jsx).
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      color: eco.surface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          EcoTopBar(
            large: true,
            title: 'Mi Bitácora',
            leading:
                const Avatar(size: 40, tone: AvatarTone.forest, emoji: '🚙'),
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
                Text('Logística de campo para hoy, 24 de Octubre',
                    style:
                        TextStyle(fontSize: 15, color: eco.onSurfaceVariant)),
                const SizedBox(height: 24),
                _weather(eco),
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
                _dayCell(eco, 'Hoy', 24, true),
                _dayCell(eco, 'Vie', 25, false),
                _dayCell(eco, 'Sáb', 26, false),
                _dayCell(eco, 'Dom', 27, false),
                _dayCell(eco, 'Lun', 28, false),
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

  Widget _weather(AppColors eco) {
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: eco.primary),
                  const SizedBox(width: 6),
                  Text('Puerto Ayora, SC',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: eco.onSurface)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('28°C',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: eco.onSurface)),
                  const SizedBox(width: 8),
                  Text('Despejado',
                      style: TextStyle(
                          fontSize: 14, color: eco.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _weatherStat(eco, Icons.water_drop, '65% HUM.'),
                  const SizedBox(width: 16),
                  _weatherStat(eco, Icons.wb_sunny, 'UV 8 (ALTO)'),
                ],
              ),
            ],
          ),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wb_sunny, size: 36, color: eco.primary),
          ),
        ],
      ),
    );
  }

  Widget _weatherStat(AppColors eco, IconData icon, String label) {
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
    return Stack(
      children: [
        Positioned(
          left: 11,
          top: 18,
          bottom: 18,
          child: Container(
              width: 2, color: eco.outlineVariant.withValues(alpha: 0.4)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            children: [
              // Active item
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -27,
                    top: 36,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: eco.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: eco.surface, width: 5),
                        boxShadow: [
                          BoxShadow(
                              color: eco.primary.withValues(alpha: 0.25),
                              blurRadius: 0,
                              spreadRadius: 4)
                        ],
                      ),
                    ),
                  ),
                  EcoCard(
                    radius: 32,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ACTIVO · 08:00 - 12:00',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: eco.primary)),
                                const SizedBox(height: 4),
                                Text('Seymour Norte',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: eco.onSurface)),
                              ],
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: eco.secondaryContainer,
                                  shape: BoxShape.circle),
                              child: const Text('🦭',
                                  style: TextStyle(fontSize: 24)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _infoRow(eco, Icons.directions_boat, 'Yate "Sea Lion III"'),
                        const SizedBox(height: 10),
                        _infoRow(
                            eco, Icons.location_on, 'Punto de desembarque seco'),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: eco.primary,
                              foregroundColor: eco.onPrimary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            icon: const Icon(Icons.play_circle, size: 18),
                            label: const Text('Iniciar Ruta',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Inactive item
              Opacity(
                opacity: 0.6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -22,
                      top: 30,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: eco.outlineVariant,
                          shape: BoxShape.circle,
                          border: Border.all(color: eco.surface, width: 3),
                        ),
                      ),
                    ),
                    DottedBorderCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PRÓXIMO · 14:00 - 17:00',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: eco.onSurfaceVariant)),
                                  const SizedBox(height: 4),
                                  Text('Estación Darwin',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          color: eco.onSurface)),
                                ],
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: eco.surfaceContainerHigh,
                                    shape: BoxShape.circle),
                                child: const Text('🐢',
                                    style: TextStyle(fontSize: 20)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoRow(eco, Icons.groups,
                              'Charla logística: Conservación Terrestre'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(AppColors eco, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: eco.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: eco.onSurfaceVariant)),
        ),
      ],
    );
  }
}

/// Card with a dashed outline (`.dashed`) used for the next, inactive item.
class DottedBorderCard extends StatelessWidget {
  const DottedBorderCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return CustomPaint(
      painter: _DashedRectPainter(eco.outlineVariant),
      child: Container(
        decoration: BoxDecoration(
          color: eco.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
        ),
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(32));
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(
            metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
