import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import 'dashboard_screen.dart' show SpeciesRow;

/// Reporte — detailed impact report (screens-extra.jsx).
class ReporteScreen extends StatelessWidget {
  const ReporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      backgroundColor: eco.surface,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'Reporte Detallado de Impacto',
              onBack: () => Navigator.pop(context),
              trailing: const EcoChip('Últimos 30 días',
                  tone: ChipTone.slate, small: true),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Row(
                    children: const [
                      Expanded(
                          child: _Kpi(
                              label: 'Total Sightings',
                              value: '15,402',
                              delta: '+4.2%')),
                      SizedBox(width: 12),
                      Expanded(
                          child: _Kpi(
                              label: 'Species Recorded',
                              value: '87',
                              delta: 'Stable',
                              deltaTone: ChipTone.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(
                          child: _Kpi(
                              label: 'Data Precision',
                              value: '94.2%',
                              delta: '✓')),
                      SizedBox(width: 12),
                      Expanded(
                          child: _Kpi(
                              label: 'Area Covered', value: '1.2k km²')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GradientPanel(
                    radius: 28,
                    dots: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🌱',
                              style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Logro de Conservación del Mes',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white)),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white),
                            children: const [
                              TextSpan(text: 'Reducción del '),
                              TextSpan(
                                  text: '12% en incidentes de basura',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w900)),
                              TextSpan(
                                  text:
                                      ' en zonas críticas gracias a las nuevas patrullas comunitarias en Bahía Academia.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EcoCard(
                    radius: 28,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Tendencia de Avistamientos',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: eco.onSurface)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.more_horiz, color: eco.outline),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _bar(eco, 50, 'SEM 01'),
                              _bar(eco, 70, 'SEM 02'),
                              _bar(eco, 60, 'SEM 03',
                                  highlight: true, peak: '1.2k'),
                              _bar(eco, 80, 'SEM 03'),
                              _bar(eco, 55, 'SEM 04'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EcoCard(
                    radius: 28,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Distribución de Hallazgos',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: eco.onSurface)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: CustomPaint(painter: _DonutChartPainter(eco)),
                        ),
                        const SizedBox(height: 16),
                        _legend(eco, eco.primary, 'Fauna', '60%'),
                        const SizedBox(height: 10),
                        _legend(eco, eco.tertiary, 'Flora', '25%'),
                        const SizedBox(height: 10),
                        _legend(
                            eco, const Color(0xFFDC2626), 'Incidentes', '15%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EcoCard(
                    radius: 28,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Especies con Mayor Impacto',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: eco.onSurface)),
                        const SizedBox(height: 16),
                        SpeciesRow(
                            name: 'Tortuga Gigante',
                            emoji: '🐢',
                            pts: '4,820',
                            pct: 95,
                            color: eco.primary),
                        const SizedBox(height: 16),
                        SpeciesRow(
                            name: 'Iguana Marina',
                            emoji: '🦎',
                            pts: '3,510',
                            pct: 70,
                            color: const Color(0xFF10B981)),
                        const SizedBox(height: 16),
                        SpeciesRow(
                            name: 'Piquero Patas Azules',
                            emoji: '🐦',
                            pts: '2,105',
                            pct: 42,
                            color: eco.tertiary),
                        const SizedBox(height: 16),
                        SpeciesRow(
                            name: 'Lobo Marino',
                            emoji: '🦭',
                            pts: '1,920',
                            pct: 38,
                            color: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Actividad por Zonas',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: eco.onSurface)),
                  ),
                  const SizedBox(height: 12),
                  const _ZoneRow(
                      name: 'Santa Cruz',
                      visits: '6.2k',
                      incidents: '12',
                      status: 'Alta',
                      tone: ChipTone.warning),
                  const SizedBox(height: 12),
                  const _ZoneRow(
                      name: 'Isabela',
                      visits: '4.8k',
                      incidents: '08',
                      status: 'Media',
                      tone: ChipTone.tertiary),
                  const SizedBox(height: 12),
                  const _ZoneRow(
                      name: 'San Cristóbal',
                      visits: '3.4k',
                      incidents: '05',
                      status: 'Estable',
                      tone: ChipTone.emerald),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(AppColors eco, double h, String label,
      {bool highlight = false, String? peak}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (peak != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: eco.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(peak,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: eco.onPrimary)),
              ),
            Container(
              height: h,
              decoration: BoxDecoration(
                color: highlight
                    ? eco.primary
                    : eco.primary.withValues(alpha: 0.25),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: eco.outline)),
          ],
        ),
      ),
    );
  }

  Widget _legend(AppColors eco, Color color, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: eco.onSurface)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: eco.onSurface)),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    this.delta,
    this.deltaTone = ChipTone.primary,
  });

  final String label;
  final String value;
  final String? delta;
  final ChipTone deltaTone;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return EcoCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: eco.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: eco.onSurface)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(delta!,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: deltaTone == ChipTone.tertiary
                        ? eco.tertiary
                        : eco.primary)),
          ],
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.name,
    required this.visits,
    required this.incidents,
    required this.status,
    required this.tone,
  });

  final String name;
  final String visits;
  final String incidents;
  final String status;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return EcoCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility,
                        size: 13, color: eco.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(visits,
                        style: TextStyle(
                            fontSize: 11, color: eco.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Icon(Icons.warning, size: 13, color: eco.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(incidents,
                        style: TextStyle(
                            fontSize: 11, color: eco.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          EcoChip(status, tone: tone),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter(this.eco);
  final AppColors eco;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    final track = Paint()
      ..color = eco.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(center, radius, track);

    final segs = [
      [60.0, eco.primary],
      [25.0, eco.tertiary],
      [15.0, const Color(0xFFDC2626)],
    ];
    double start = -math.pi / 2;
    for (final s in segs) {
      final sweep = 2 * math.pi * (s[0] as double) / 100;
      final paint = Paint()
        ..color = s[1] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          sweep, false, paint);
      start += sweep;
    }

    final total = TextPainter(
      text: TextSpan(
          text: '15.4k',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: eco.onSurface)),
      textDirection: TextDirection.ltr,
    )..layout();
    total.paint(
        canvas, center - Offset(total.width / 2, total.height / 2 + 6));

    final lbl = TextPainter(
      text: TextSpan(
          text: 'TOTAL',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: eco.onSurfaceVariant)),
      textDirection: TextDirection.ltr,
    )..layout();
    lbl.paint(canvas, center - Offset(lbl.width / 2, lbl.height / 2 - 12));
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) => old.eco != eco;
}
