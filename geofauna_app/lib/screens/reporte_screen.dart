import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import 'dashboard_screen.dart' show SpeciesRow;

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));

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
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('fieldRecords')
                    .where('createdAt',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('Sin datos disponibles',
                          style: TextStyle(color: eco.onSurface)),
                    );
                  }

                  final records = snapshot.data!.docs;
                  final totalSightings = records.fold<int>(
                      0, (acc, doc) => acc + (doc['quantity'] as int? ?? 1));
                  final uniqueSpecies = records
                      .map((doc) => doc['speciesName'] as String?)
                      .where((s) => s != null && s.isNotEmpty)
                      .toSet()
                      .length;
                  final areaCovered = _calculateAreaCovered(records);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Kpi(
                              label: 'Total de Avistamientos',
                              value: _formatNumber(totalSightings),
                              delta: '+4.2%',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Kpi(
                              label: 'Especies Registradas',
                              value: uniqueSpecies.toString(),
                              delta: 'Estable',
                              deltaTone: ChipTone.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _Kpi(
                              label: 'Área Cubierta',
                              value: areaCovered,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildConservationPanel(context, eco),
                      const SizedBox(height: 16),
                      _buildTrendPanel(context, eco, records),
                      const SizedBox(height: 16),
                      _buildDistributionPanel(context, eco, records),
                      const SizedBox(height: 16),
                      _buildTopSpeciesPanel(context, eco, records),
                      const SizedBox(height: 16),
                      _buildZoneActivityPanel(context, eco, records),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConservationPanel(BuildContext context, AppColors eco) {
    return GradientPanel(
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
            child: const Text('🌱', style: TextStyle(fontSize: 22)),
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
                  fontSize: 14, height: 1.4, color: Colors.white),
              children: const [
                TextSpan(text: 'Reducción del '),
                TextSpan(
                    text: '12% en incidentes de basura',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                TextSpan(
                    text:
                        ' en zonas críticas gracias a las nuevas patrullas comunitarias en Bahía Academia.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPanel(BuildContext context, AppColors eco,
      List<QueryDocumentSnapshot> records) {
    return EcoCard(
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
                _bar(eco, 60, 'SEM 03', highlight: true, peak: '1.2k'),
                _bar(eco, 80, 'SEM 03'),
                _bar(eco, 55, 'SEM 04'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionPanel(BuildContext context, AppColors eco,
      List<QueryDocumentSnapshot> records) {
    final distribution = _calculateDistribution(records);
    return EcoCard(
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
            child: CustomPaint(
              painter: _DonutChartPainter(eco, distribution),
            ),
          ),
          const SizedBox(height: 16),
          _legend(eco, eco.primary, 'Fauna', '${distribution['fauna']}%'),
          const SizedBox(height: 10),
          _legend(eco, eco.tertiary, 'Flora', '${distribution['flora']}%'),
          const SizedBox(height: 10),
          _legend(eco, const Color(0xFFDC2626), 'Incidentes',
              '${distribution['incidents']}%'),
        ],
      ),
    );
  }

  Widget _buildTopSpeciesPanel(BuildContext context, AppColors eco,
      List<QueryDocumentSnapshot> records) {
    final topSpecies = _getTopSpecies(records);
    return EcoCard(
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
          ...List.generate(
            topSpecies.length,
            (i) {
              final species = topSpecies[i];
              final colors = [
                eco.primary,
                const Color(0xFF10B981),
                eco.tertiary,
                const Color(0xFFF59E0B),
              ];
              return Column(
                children: [
                  SpeciesRow(
                    name: species['name'] as String,
                    emoji: species['emoji'] as String,
                    pts: species['count'].toString(),
                    pct: species['percentage'] as int,
                    color: colors[i % colors.length],
                  ),
                  if (i < topSpecies.length - 1) const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZoneActivityPanel(BuildContext context, AppColors eco,
      List<QueryDocumentSnapshot> records) {
    final zoneActivity = _getZoneActivity(records);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Actividad por Zonas',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: eco.onSurface)),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          zoneActivity.length,
          (i) {
            final zone = zoneActivity[i];
            final statusMap = {
              'Alta': ('Alta', ChipTone.warning),
              'Media': ('Media', ChipTone.tertiary),
              'Baja': ('Estable', ChipTone.emerald),
            };
            final status = statusMap[zone['status']] ?? ('Desconocido', ChipTone.slate);
            return Column(
              children: [
                _ZoneRow(
                  name: zone['name'] as String,
                  visits: '${zone['count']}',
                  incidents: '${zone['incidents']}',
                  status: status.$1,
                  tone: status.$2,
                ),
                if (i < zoneActivity.length - 1) const SizedBox(height: 12),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _calculateAreaCovered(List<QueryDocumentSnapshot> records) {
    if (records.isEmpty) return '0 km²';

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final doc in records) {
      final location = doc['location'];
      if (location is GeoPoint) {
        minLat = math.min(minLat, location.latitude);
        maxLat = math.max(maxLat, location.latitude);
        minLng = math.min(minLng, location.longitude);
        maxLng = math.max(maxLng, location.longitude);
      }
    }

    if (minLat.isInfinite || maxLat.isInfinite) return '0 km²';

    const earthRadiusKm = 6371.0;
    final dLat = (maxLat - minLat) * math.pi / 180;
    final dLng = (maxLng - minLng) * math.pi / 180;
    final area = earthRadiusKm * dLat * earthRadiusKm * dLng;
    final aboveArea = area.abs();

    if (aboveArea < 1) {
      return '${(aboveArea * 1000).toStringAsFixed(0)} m²';
    } else if (aboveArea >= 1000) {
      return '${(aboveArea / 1000).toStringAsFixed(1)}k km²';
    }
    return '${aboveArea.toStringAsFixed(1)} km²';
  }

  Map<String, int> _calculateDistribution(List<QueryDocumentSnapshot> records) {
    int fauna = 0;
    int flora = 0;
    int incidents = 0;

    for (final doc in records) {
      final category = doc['category'] as String?;
      final quantity = doc['quantity'] as int? ?? 1;
      switch (category?.toLowerCase()) {
        case 'fauna':
          fauna += quantity;
        case 'flora':
          flora += quantity;
        case 'incident':
        case 'trash':
          incidents += quantity;
        default:
          break;
      }
    }

    final total = fauna + flora + incidents;
    if (total == 0) return {'fauna': 0, 'flora': 0, 'incidents': 0};

    return {
      'fauna': ((fauna / total) * 100).round(),
      'flora': ((flora / total) * 100).round(),
      'incidents': ((incidents / total) * 100).round(),
    };
  }

  List<Map<String, dynamic>> _getTopSpecies(
      List<QueryDocumentSnapshot> records) {
    final speciesMap = <String, int>{};

    for (final doc in records) {
      final species = doc['speciesName'] as String?;
      if (species != null && species.isNotEmpty) {
        speciesMap[species] = (speciesMap[species] ?? 0) + (doc['quantity'] as int? ?? 1);
      }
    }

    final sorted = speciesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = speciesMap.values.fold<int>(0, (acc, val) => acc + val);

    return sorted.take(4).map((entry) {
      return {
        'name': entry.key,
        'emoji': _getSpeciesEmoji(entry.key),
        'count': entry.value,
        'percentage': total > 0 ? ((entry.value / total) * 100).round() : 0,
      };
    }).toList();
  }

  String _getSpeciesEmoji(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('tortuga')) return '🐢';
    if (lower.contains('iguana')) return '🦎';
    if (lower.contains('piquero')) return '🐦';
    if (lower.contains('lobo')) return '🦭';
    return '🦁';
  }

  List<Map<String, dynamic>> _getZoneActivity(
      List<QueryDocumentSnapshot> records) {
    final zoneMap = <String, Map<String, int>>{};

    for (final doc in records) {
      final placeLabel = doc['placeLabel'] as String? ?? 'Desconocido';
      if (zoneMap[placeLabel] == null) {
        zoneMap[placeLabel] = {'count': 0, 'incidents': 0};
      }
      zoneMap[placeLabel]!['count'] =
          zoneMap[placeLabel]!['count']! + (doc['quantity'] as int? ?? 1);

      final category = doc['category'] as String?;
      if (category == 'incident' || category == 'trash') {
        zoneMap[placeLabel]!['incidents'] = zoneMap[placeLabel]!['incidents']! + 1;
      }
    }

    final sorted = zoneMap.entries.toList()
      ..sort((a, b) => b.value['count']!.compareTo(a.value['count']!));

    return sorted.take(3).map((entry) {
      final count = entry.value['count'] ?? 0;
      final status = count > 50 ? 'Alta' : count > 20 ? 'Media' : 'Baja';
      return {
        'name': entry.key,
        'count': count,
        'incidents': entry.value['incidents'] ?? 0,
        'status': status,
      };
    }).toList();
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
  _DonutChartPainter(this.eco, this.distribution);
  final AppColors eco;
  final Map<String, int> distribution;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 12;
    final track = Paint()
      ..color = eco.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(center, radius, track);

    final fauna = distribution['fauna'] as double? ?? 0;
    final flora = distribution['flora'] as double? ?? 0;
    final incidents = distribution['incidents'] as double? ?? 0;

    final segs = [
      [fauna, eco.primary],
      [flora, eco.tertiary],
      [incidents, const Color(0xFFDC2626)],
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
          text: 'TOTAL',
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
          text: 'REGISTROS',
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
  bool shouldRepaint(_DonutChartPainter old) =>
      old.eco != eco || old.distribution != distribution;
}
