import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/painters.dart';
import 'reporte_screen.dart';

/// Dashboard (Inicio) — weather, live map, leaderboards, community monitor.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      color: eco.surface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          EcoTopBar(
            title: 'EcoGuía Galápagos',
            leading: CircleIconButton(
              icon: Icons.menu,
              bg: eco.surfaceContainerLow,
              iconColor: eco.onSurface,
              onTap: () {},
            ),
            trailing: const [
              Avatar(tone: AvatarTone.forest, emoji: '🦫', size: 40, status: AvatarStatus.on),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _weatherMini(eco),
                const SizedBox(height: 32),
                _map(eco),
                const SizedBox(height: 32),
                _recognition(context, eco),
                const SizedBox(height: 32),
                _leaders(eco),
                const SizedBox(height: 32),
                _monitor(context, eco),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(AppColors eco, String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
          color: eco.primary));

  Widget _weatherMini(AppColors eco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(eco, 'Estado del Tiempo'),
        const SizedBox(height: 4),
        Text('Puerto Ayora, SC',
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
              child: Text('Isla Santa Cruz · Estación Charles Darwin',
                  style:
                      TextStyle(fontSize: 14, color: eco.onSurfaceVariant)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        EcoCard(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Text('☀️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('28°C',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: eco.onSurface)),
                  const SizedBox(height: 4),
                  Text('HUMEDAD 64% · UV 11+',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: eco.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _map(AppColors eco) {
    return TopoMap(
      minHeight: 240,
      children: [
        Positioned(
          top: 16,
          left: 16,
          child: Glass(
            borderRadius: BorderRadius.circular(999),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16, color: eco.primary),
                const SizedBox(width: 8),
                Text('12 Guías Activos',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface)),
                const SizedBox(width: 12),
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('EN VIVO',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: eco.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        for (final p in const [
          [0.32, 0.30, '🐢'],
          [0.58, 0.44, '🦎'],
          [0.44, 0.62, '🦅'],
          [0.22, 0.52, '📍'],
        ])
          Positioned(
            left: (p[0] as double) * 320,
            top: (p[1] as double) * 220,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: eco.primary, width: 3),
              ),
              child: Text(p[2] as String, style: const TextStyle(fontSize: 16)),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: eco.primary,
              foregroundColor: eco.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
            ),
            icon: const Icon(Icons.open_in_full, size: 14),
            label: const Text('Expandir Mapa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _recognition(BuildContext context, AppColors eco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(eco, 'Prestigio e Impacto'),
                const SizedBox(height: 4),
                Text('Centro de Reconocimiento',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: eco.onSurface)),
              ],
            ),
            Text('Perfil Completo',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: eco.primary)),
          ],
        ),
        const SizedBox(height: 12),
        EcoCard(
          radius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Text('TOP CONTRIBUIDORES',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: eco.onSurfaceVariant)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Expanded(
                      child: _Podium(
                          icon: Icons.military_tech,
                          iconColor: Color(0xFF9CA3AF),
                          name: 'Elena R.',
                          pts: '982',
                          tone: AvatarTone.slate,
                          emoji: '👩‍🔬')),
                  SizedBox(width: 12),
                  Expanded(
                      child: _Podium(
                          icon: Icons.emoji_events,
                          iconColor: Color(0xFFF59E0B),
                          name: 'Mateo L.',
                          pts: '1,245',
                          tone: AvatarTone.primary,
                          emoji: '🧑‍🌾',
                          highlight: true)),
                  SizedBox(width: 12),
                  Expanded(
                      child: _Podium(
                          icon: Icons.workspace_premium,
                          iconColor: Color(0xFFC87F5B),
                          name: 'Carlos J.',
                          pts: '856',
                          tone: AvatarTone.forest,
                          emoji: '🦫')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leaders(AppColors eco) {
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Líderes por Categoría',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: eco.onSurface)),
              const EcoChip('Actualizado hoy', tone: ChipTone.emerald),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                  child: _LeaderCard(
                      name: 'Elena R.',
                      role: 'Campeón',
                      cat: 'Fauna',
                      pts: '421 pts',
                      tone: AvatarTone.primary,
                      chip: ChipTone.emerald,
                      emoji: '👩‍🔬')),
              SizedBox(width: 12),
              Expanded(
                  child: _LeaderCard(
                      name: 'Mateo L.',
                      role: 'Experto',
                      cat: 'Flora',
                      pts: '388 pts',
                      tone: AvatarTone.blue,
                      chip: ChipTone.tertiary,
                      emoji: '🧑‍🌾')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                  child: _LeaderCard(
                      name: 'Carlos J.',
                      role: 'Avanzado',
                      cat: 'Incidentes',
                      pts: '254 pts',
                      tone: AvatarTone.sand,
                      chip: ChipTone.warning,
                      emoji: '🦫')),
              SizedBox(width: 12),
              Expanded(
                  child: _LeaderCard(
                      name: 'Sofía M.',
                      role: 'Campeón',
                      cat: 'Basura',
                      pts: '512 pts',
                      tone: AvatarTone.primary,
                      chip: ChipTone.emerald,
                      emoji: '👩')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monitor(BuildContext context, AppColors eco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(eco, 'Monitor de Comunidad'),
                const SizedBox(height: 4),
                Text('Análisis de Datos',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: eco.onSurface)),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReporteScreen())),
              child: Row(
                children: [
                  Text('Ver reporte',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: eco.primary)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: eco.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        EcoCard(
          radius: 28,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AVISTAMIENTOS TOTALES',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: eco.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('15,402',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              color: eco.onSurface)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const EcoChip('+15.2%', tone: ChipTone.emerald),
                      const SizedBox(height: 4),
                      Text('Vs. mes anterior',
                          style: TextStyle(
                              fontSize: 10, color: eco.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final entry in const [34, 42, 38, 56, 48, 70, 92]
                        .asMap()
                        .entries)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            height: entry.value * 0.8,
                            decoration: BoxDecoration(
                              color: entry.key == 6
                                  ? eco.primary
                                  : eco.primary.withValues(alpha: 0.25),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EcoCard(
          radius: 28,
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRECISIÓN DE DATOS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: eco.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('94.2%',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: eco.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: eco.primary),
                      const SizedBox(width: 4),
                      Text('Calidad de grado científico',
                          style: TextStyle(
                              fontSize: 11, color: eco.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(painter: _DonutPainter(94, eco)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EcoCard(
          radius: 28,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Especies con Mayor Impacto',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: eco.onSurface)),
                  Text('TOP REPORTADAS',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: eco.outline)),
                ],
              ),
              const SizedBox(height: 16),
              SpeciesRow(
                  name: 'Tortuga Gigante',
                  emoji: '🐢',
                  pts: '4,201',
                  pct: 92,
                  color: eco.primary),
              const SizedBox(height: 12),
              SpeciesRow(
                  name: 'Iguana Marina',
                  emoji: '🦎',
                  pts: '3,120',
                  pct: 68,
                  color: const Color(0xFF10B981)),
              const SizedBox(height: 12),
              SpeciesRow(
                  name: 'Piquero Patas Azules',
                  emoji: '🐦',
                  pts: '2,840',
                  pct: 60,
                  color: eco.tertiary),
              const SizedBox(height: 12),
              SpeciesRow(
                  name: 'Lobo Marino',
                  emoji: '🦭',
                  pts: '1,950',
                  pct: 42,
                  color: const Color(0xFFF59E0B)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.pts,
    required this.tone,
    required this.emoji,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final String pts;
  final AvatarTone tone;
  final String emoji;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Avatar(size: 56, tone: tone, emoji: emoji),
        const SizedBox(height: 8),
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: eco.onSurface)),
        const SizedBox(height: 2),
        Text(pts,
            style: TextStyle(
                fontSize: highlight ? 20 : 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: highlight ? eco.primary : eco.onSurface)),
        Text('REGISTROS',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: eco.outline)),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.name,
    required this.role,
    required this.cat,
    required this.pts,
    required this.tone,
    required this.chip,
    required this.emoji,
  });

  final String name;
  final String role;
  final String cat;
  final String pts;
  final AvatarTone tone;
  final ChipTone chip;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(size: 40, tone: tone, emoji: emoji),
              const SizedBox(width: 12),
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
                    EcoChip(role, tone: chip, small: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(cat.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: eco.onSurfaceVariant)),
              Text(pts,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: eco.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal labelled progress bar reused on Dashboard + Reporte.
class SpeciesRow extends StatelessWidget {
  const SpeciesRow({
    super.key,
    required this.name,
    required this.emoji,
    required this.pts,
    required this.pct,
    required this.color,
  });

  final String name;
  final String emoji;
  final String pts;
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: eco.onSurface)),
              ],
            ),
            Text('$pts sightings',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: eco.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: eco.surfaceContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.value, this.eco);
  final int value;
  final AppColors eco;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..color = eco.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final arc = Paint()
      ..color = eco.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * value / 100, false, arc);
    final tp = TextPainter(
      text: TextSpan(
          text: '$value%',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: eco.onSurface)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.value != value || old.eco != eco;
}
