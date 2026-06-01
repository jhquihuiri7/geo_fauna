import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/live_map.dart';
import '../widgets/user_avatar.dart';
import '../widgets/weather_header.dart';
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
            trailing: const [UserAvatar(size: 40, status: AvatarStatus.on)],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WeatherHeader(),
                const SizedBox(height: 32),
                _liveData(context, eco),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(AppColors eco, String t) => Text(
    t.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
      color: eco.primary,
    ),
  );

  /// Un solo stream de `fieldRecords` alimenta tanto el mapa de avistamientos
  /// como las secciones de estadísticas, para no abrir dos listeners.
  Widget _liveData(BuildContext context, AppColors eco) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('fieldRecords').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final sightings = <MapSighting>[];
        for (final doc in docs) {
          final data = doc.data();
          final point = _sightingPoint(data);
          if (point == null) continue;
          sightings.add(
            MapSighting(
              point: point,
              categoryKey: _normalizeCategory(
                _firstNonEmpty([
                  _stringValue(data['category']),
                  _stringValue(data['type']),
                ]),
              ),
              species: _firstNonEmpty([
                _stringValue(data['speciesName']),
                _stringValue(data['species']),
                _stringValue(data['commonName']),
              ]),
              placeLabel: _firstNonEmpty([
                _stringValue(data['placeLabel']),
                _stringValue(data['placeName']),
              ]),
            ),
          );
        }
        return Column(
          children: [
            _mapView(eco, sightings),
            const SizedBox(height: 32),
            _dataSections(context, eco, snap),
          ],
        );
      },
    );
  }

  Widget _mapView(AppColors eco, List<MapSighting> sightings) {
    return LiveMap(
      height: 240,
      expandable: true,
      fullscreenTitle: 'Avistamientos',
      sightings: sightings,
      overlays: [
        Positioned(
          top: 16,
          left: 16,
          child: Glass(
            borderRadius: BorderRadius.circular(999),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location, size: 16, color: eco.primary),
                const SizedBox(width: 8),
                Text(
                  'Tu ubicación',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: eco.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'EN VIVO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: eco.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataSections(
    BuildContext context,
    AppColors eco,
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
      return _loadingData(eco);
    }
    if (snap.hasError) {
      return _dataError(eco, snap.error!);
    }

    final records =
        snap.data?.docs
            .map((doc) => _FieldRecord.fromMap(doc.id, doc.data()))
            .toList() ??
        const <_FieldRecord>[];
    final data = _DashboardData.fromRecords(records);

    return Column(
      children: [
        _recognition(context, eco, data),
        const SizedBox(height: 32),
        _leaders(eco, data),
        const SizedBox(height: 32),
        _monitor(context, eco, data),
      ],
    );
  }

  Widget _loadingData(AppColors eco) {
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: eco.primary,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Cargando datos reales...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: eco.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataError(AppColors eco, Object error) {
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: eco.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No se pudieron cargar los registros reales: $error',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: eco.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recognition(
    BuildContext context,
    AppColors eco,
    _DashboardData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(eco, 'Prestigio e Impacto'),
                  const SizedBox(height: 4),
                  Text(
                    'Centro de Reconocimiento',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: eco.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            EcoChip(
              '${data.totalRecords} registros',
              tone: ChipTone.emerald,
              small: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        EcoCard(
          radius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Text(
                'TOP CONTRIBUIDORES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: eco.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (data.contributors.isEmpty)
                _emptyState(
                  eco,
                  icon: Icons.groups_outlined,
                  title: 'Sin contribuciones registradas',
                  message:
                      'Cuando existan documentos en fieldRecords, aparecerán aquí.',
                )
              else
                Column(
                  children: [
                    // 1er lugar: centrado arriba
                    Center(
                      child: _Podium(
                        icon: Icons.emoji_events,
                        iconColor: const Color(0xFFF59E0B),
                        name: data.contributors[0].name,
                        pts: _formatInt(data.contributors[0].count),
                        tone: _toneForIndex(0),
                        photoUrl: data.contributors[0].photoUrl,
                        highlight: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 2do y 3er lugar: abajo en fila
                    if (data.contributors.length > 1)
                      Row(
                        children: [
                          // 2do lugar: izquierda
                          Expanded(
                            child: Center(
                              child: _Podium(
                                icon: Icons.military_tech,
                                iconColor: const Color(0xFF9CA3AF),
                                name: data.contributors[1].name,
                                pts: _formatInt(data.contributors[1].count),
                                tone: _toneForIndex(1),
                                photoUrl: data.contributors[1].photoUrl,
                                highlight: false,
                              ),
                            ),
                          ),
                          // 3er lugar: derecha
                          if (data.contributors.length > 2)
                            Expanded(
                              child: Center(
                                child: _Podium(
                                  icon: Icons.workspace_premium,
                                  iconColor: const Color(0xFFC87F5B),
                                  name: data.contributors[2].name,
                                  pts: _formatInt(data.contributors[2].count),
                                  tone: _toneForIndex(2),
                                  photoUrl: data.contributors[2].photoUrl,
                                  highlight: false,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leaders(AppColors eco, _DashboardData data) {
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Líderes por Categoría',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: eco.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              EcoChip(
                '${data.categoryLeaders.length} categorías',
                tone: ChipTone.emerald,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.categoryLeaders.isEmpty)
            _emptyState(
              eco,
              icon: Icons.leaderboard_outlined,
              title: 'Sin líderes por categoría',
              message:
                  'Los líderes se calculan desde los registros reales por categoría.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final leaders = data.categoryLeaders.take(4).toList();
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < leaders.length; i++)
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _LeaderCard(
                          name: leaders[i].name,
                          cat: leaders[i].categoryLabel,
                          count: leaders[i].count,
                          tone: _toneForIndex(i),
                          chip: _chipForCategory(leaders[i].categoryKey),
                          photoUrl: leaders[i].photoUrl,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _monitor(BuildContext context, AppColors eco, _DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(eco, 'Monitor de Comunidad'),
                  const SizedBox(height: 4),
                  Text(
                    'Análisis de Datos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: eco.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReporteScreen()),
              ),
              child: Row(
                children: [
                  Text(
                    'Ver reporte',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: eco.primary,
                    ),
                  ),
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
                      Text(
                        'REGISTROS TOTALES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatInt(data.totalRecords),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: eco.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      EcoChip(
                        data.deltaLabel,
                        tone: data.deltaTone,
                        small: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vs. mes anterior',
                        style: TextStyle(
                          fontSize: 10,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _weeklyBars(eco, data),
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
                  Expanded(
                    child: Text(
                      'Especies con Mayor Impacto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TOP REPORTADAS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: eco.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.species.isEmpty)
                _emptyState(
                  eco,
                  icon: Icons.eco_outlined,
                  title: 'Sin especies reportadas',
                  message:
                      'Las especies aparecerán cuando fieldRecords tenga speciesName.',
                )
              else
                for (final entry
                    in data.species.take(4).toList().asMap().entries)
                  Padding(
                    padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 12),
                    child: SpeciesRow(
                      name: entry.value.name,
                      emoji: _categoryGlyph(entry.value.categoryKey),
                      pts: _formatInt(entry.value.count),
                      pct: entry.value.percent,
                      color: _colorForIndex(eco, entry.key),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weeklyBars(AppColors eco, _DashboardData data) {
    if (data.weeklyCounts.every((value) => value == 0)) {
      return SizedBox(
        height: 80,
        child: _emptyState(
          eco,
          icon: Icons.bar_chart,
          title: 'Sin registros recientes',
          message: 'No hay actividad en los últimos 7 días.',
          compact: true,
        ),
      );
    }

    final maxCount = data.weeklyCounts.reduce(math.max);
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final entry in data.weeklyCounts.asMap().entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  height: math.max(6, 76 * entry.value / maxCount),
                  decoration: BoxDecoration(
                    color: entry.key == data.weeklyCounts.length - 1
                        ? eco.primary
                        : eco.primary.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(
    AppColors eco, {
    required IconData icon,
    required String title,
    required String message,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
      ),
      child: Row(
        children: [
          Icon(icon, color: eco.outline, size: compact ? 20 : 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w800,
                    color: eco.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: eco.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.totalRecords,
    required this.currentPeriodRecords,
    required this.previousPeriodRecords,
    required this.weeklyCounts,
    required this.contributors,
    required this.categoryLeaders,
    required this.species,
  });

  final int totalRecords;
  final int currentPeriodRecords;
  final int previousPeriodRecords;
  final List<int> weeklyCounts;
  final List<_ContributorStat> contributors;
  final List<_CategoryLeader> categoryLeaders;
  final List<_SpeciesStat> species;

  String get deltaLabel {
    if (currentPeriodRecords == 0 && previousPeriodRecords == 0) {
      return totalRecords == 0 ? 'Sin actividad' : 'Sin fecha';
    }
    if (previousPeriodRecords == 0) return '+$currentPeriodRecords nuevos';

    final pct =
        ((currentPeriodRecords - previousPeriodRecords) /
            previousPeriodRecords) *
        100;
    final rounded = pct.round();
    return '${rounded >= 0 ? '+' : ''}$rounded%';
  }

  ChipTone get deltaTone {
    if (currentPeriodRecords >= previousPeriodRecords) return ChipTone.emerald;
    return ChipTone.warning;
  }

  static _DashboardData fromRecords(List<_FieldRecord> records) {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 30));
    final previousStart = now.subtract(const Duration(days: 60));

    final contributors = <String, _MutableContributor>{};
    final categories = <String, Map<String, _MutableContributor>>{};
    final species = <String, _MutableSpecies>{};
    final weeklyCounts = List<int>.filled(7, 0);
    var currentPeriodRecords = 0;
    var previousPeriodRecords = 0;

    for (final record in records) {
      final date = record.date;
      if (date != null) {
        if (!date.isBefore(currentStart) && !date.isAfter(now)) {
          currentPeriodRecords++;
        } else if (!date.isBefore(previousStart) &&
            date.isBefore(currentStart)) {
          previousPeriodRecords++;
        }

        final daysAgo = now
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          weeklyCounts[6 - daysAgo]++;
        }
      }

      final authorKey = record.authorId ?? record.authorName;
      contributors
          .putIfAbsent(
            authorKey,
            () => _MutableContributor(
              name: record.authorName,
              photoUrl: record.authorPhotoUrl,
            ),
          )
          .count++;

      final categoryKey = record.categoryKey;
      final categoryAuthors = categories.putIfAbsent(
        categoryKey,
        () => <String, _MutableContributor>{},
      );
      categoryAuthors
          .putIfAbsent(
            authorKey,
            () => _MutableContributor(
              name: record.authorName,
              photoUrl: record.authorPhotoUrl,
            ),
          )
          .count++;

      if (record.speciesName != null) {
        species
            .putIfAbsent(
              record.speciesName!,
              () => _MutableSpecies(
                name: record.speciesName!,
                categoryKey: categoryKey,
              ),
            )
            .count++;
      }

    }

    final contributorStats =
        contributors.values
            .map(
              (c) => _ContributorStat(
                name: c.name,
                count: c.count,
                photoUrl: c.photoUrl,
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    final categoryLeaderStats = <_CategoryLeader>[];
    for (final entry in categories.entries) {
      final leaders = entry.value.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      if (leaders.isEmpty) continue;
      final leader = leaders.first;
      categoryLeaderStats.add(
        _CategoryLeader(
          categoryKey: entry.key,
          categoryLabel: _categoryLabel(entry.key),
          name: leader.name,
          count: leader.count,
          photoUrl: leader.photoUrl,
        ),
      );
    }
    categoryLeaderStats.sort((a, b) => b.count.compareTo(a.count));

    final maxSpeciesCount = species.values.fold<int>(
      0,
      (max, item) => math.max(max, item.count),
    );
    final speciesStats =
        species.values
            .map(
              (s) => _SpeciesStat(
                name: s.name,
                count: s.count,
                categoryKey: s.categoryKey,
                percent: maxSpeciesCount == 0
                    ? 0
                    : (s.count * 100 / maxSpeciesCount).round(),
              ),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return _DashboardData(
      totalRecords: records.length,
      currentPeriodRecords: currentPeriodRecords,
      previousPeriodRecords: previousPeriodRecords,
      weeklyCounts: weeklyCounts,
      contributors: contributorStats,
      categoryLeaders: categoryLeaderStats,
      species: speciesStats,
    );
  }
}

class _FieldRecord {
  _FieldRecord({
    required this.id,
    required this.authorName,
    required this.categoryKey,
    this.authorId,
    this.authorPhotoUrl,
    this.speciesName,
    this.date,
    this.integrityScore,
    this.status,
  });

  final String id;
  final String? authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String categoryKey;
  final String? speciesName;
  final DateTime? date;
  final int? integrityScore;
  final String? status;

  factory _FieldRecord.fromMap(String id, Map<String, dynamic> data) {
    final authorSnapshot = data['authorSnapshot'] is Map
        ? data['authorSnapshot'] as Map
        : null;
    final authorId = _firstNonEmpty([
      _stringValue(data['authorId']),
      _stringValue(data['createdBy']),
      _stringValue(data['userId']),
      _stringValue(data['uid']),
    ]);
    final authorName =
        _firstNonEmpty([
          _stringValue(authorSnapshot?['name']),
          _stringValue(authorSnapshot?['displayName']),
          _stringValue(data['authorName']),
          _stringValue(data['userName']),
          _stringValue(data['name']),
        ]) ??
        _fallbackUserName(authorId);

    return _FieldRecord(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: _firstNonEmpty([
        _stringValue(authorSnapshot?['photoUrl']),
        _stringValue(authorSnapshot?['photoURL']),
        _stringValue(data['authorPhotoUrl']),
        _stringValue(data['photoUrl']),
      ]),
      categoryKey: _normalizeCategory(
        _firstNonEmpty([
          _stringValue(data['category']),
          _stringValue(data['type']),
        ]),
      ),
      speciesName: _firstNonEmpty([
        _stringValue(data['speciesName']),
        _stringValue(data['species']),
        _stringValue(data['commonName']),
      ]),
      date:
          _toDate(data['observedAt']) ??
          _toDate(data['createdAt']) ??
          _toDate(data['date']),
      integrityScore: _toInt(data['integrityScore']),
      status: _firstNonEmpty([_stringValue(data['status'])]),
    );
  }
}

class _ContributorStat {
  const _ContributorStat({
    required this.name,
    required this.count,
    this.photoUrl,
  });

  final String name;
  final int count;
  final String? photoUrl;
}

class _CategoryLeader {
  const _CategoryLeader({
    required this.categoryKey,
    required this.categoryLabel,
    required this.name,
    required this.count,
    this.photoUrl,
  });

  final String categoryKey;
  final String categoryLabel;
  final String name;
  final int count;
  final String? photoUrl;
}

class _SpeciesStat {
  const _SpeciesStat({
    required this.name,
    required this.count,
    required this.categoryKey,
    required this.percent,
  });

  final String name;
  final int count;
  final String categoryKey;
  final int percent;
}

class _MutableContributor {
  _MutableContributor({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;
  int count = 0;
}

class _MutableSpecies {
  _MutableSpecies({required this.name, required this.categoryKey});

  final String name;
  final String categoryKey;
  int count = 0;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  return value.toString();
}

String _fallbackUserName(String? uid) {
  if (uid == null || uid.isEmpty) return 'Usuario sin nombre';
  final visible = uid.length <= 6 ? uid : uid.substring(uid.length - 6);
  return 'Usuario $visible';
}

String _normalizeCategory(String? value) {
  final v = (value ?? 'otros').trim().toLowerCase();
  return switch (v) {
    'fauna' || 'animal' || 'animals' => 'fauna',
    'flora' || 'plant' || 'plants' => 'flora',
    'incidente' || 'incident' || 'incidents' => 'incident',
    'basura' || 'trash' || 'waste' => 'trash',
    _ => 'otros',
  };
}

String _categoryLabel(String key) {
  return switch (key) {
    'fauna' => 'Fauna',
    'flora' => 'Flora',
    'incident' => 'Incidentes',
    'trash' => 'Basura',
    _ => 'Otros',
  };
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int? _toInt(Object? value) {
  if (value is num) return value.round().clamp(0, 100).toInt();
  if (value is String) return int.tryParse(value)?.clamp(0, 100).toInt();
  return null;
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Extrae la ubicación de un fieldRecord: `location` (GeoPoint) o los campos
/// lat/lng sueltos. Devuelve null si no hay coordenadas válidas. Descarta
/// valores no finitos (NaN / Infinity) y fuera de rango para que un registro
/// con GPS corrupto no rompa el mapa ("LatLng is not finite").
LatLng? _sightingPoint(Map<String, dynamic> data) {
  double? latitude;
  double? longitude;
  final location = data['location'];
  if (location is GeoPoint) {
    latitude = location.latitude;
    longitude = location.longitude;
  } else {
    latitude = _toDouble(
      data['latitude'] ?? data['lat'] ?? data['locationLatitude'],
    );
    longitude = _toDouble(
      data['longitude'] ??
          data['lng'] ??
          data['lon'] ??
          data['locationLongitude'],
    );
  }
  if (latitude == null || longitude == null) return null;
  if (!latitude.isFinite || !longitude.isFinite) return null;
  if (latitude.abs() > 90 || longitude.abs() > 180) return null;
  return LatLng(latitude, longitude);
}

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

AvatarTone _toneForIndex(int index) {
  return switch (index % 6) {
    0 => AvatarTone.primary,
    1 => AvatarTone.slate,
    2 => AvatarTone.forest,
    3 => AvatarTone.blue,
    4 => AvatarTone.sand,
    _ => AvatarTone.teal,
  };
}

ChipTone _chipForCategory(String key) {
  return switch (key) {
    'fauna' => ChipTone.emerald,
    'flora' => ChipTone.tertiary,
    'incident' => ChipTone.warning,
    'trash' => ChipTone.primary,
    _ => ChipTone.slate,
  };
}

String _categoryGlyph(String key) {
  return switch (key) {
    'fauna' => 'F',
    'flora' => 'L',
    'incident' => '!',
    'trash' => 'B',
    _ => '*',
  };
}

Color _colorForIndex(AppColors eco, int index) {
  return switch (index % 4) {
    0 => eco.primary,
    1 => const Color(0xFF10B981),
    2 => eco.tertiary,
    _ => const Color(0xFFF59E0B),
  };
}

Widget _profileAvatar({
  required String name,
  required AvatarTone tone,
  required double size,
  String? photoUrl,
}) {
  if (photoUrl == null || photoUrl.isEmpty) {
    return Avatar(name: name, size: size, tone: tone);
  }
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      image: DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover),
    ),
  );
}

class _Podium extends StatelessWidget {
  const _Podium({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.pts,
    required this.tone,
    this.photoUrl,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final String pts;
  final AvatarTone tone;
  final String? photoUrl;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        _profileAvatar(name: name, tone: tone, size: 56, photoUrl: photoUrl),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: eco.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          pts,
          style: TextStyle(
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: highlight ? eco.primary : eco.onSurface,
          ),
        ),
        Text(
          'REGISTROS',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: eco.outline,
          ),
        ),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.name,
    required this.cat,
    required this.count,
    required this.tone,
    required this.chip,
    this.photoUrl,
  });

  final String name;
  final String cat;
  final int count;
  final AvatarTone tone;
  final ChipTone chip;
  final String? photoUrl;

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
              _profileAvatar(
                name: name,
                tone: tone,
                size: 40,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    EcoChip(
                      '${_formatInt(count)} reg.',
                      tone: chip,
                      small: true,
                    ),
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
              Expanded(
                child: Text(
                  cat.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: eco.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatInt(count)} reg.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: eco.onSurface,
                ),
              ),
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
            Expanded(
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: eco.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pts registros',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: eco.onSurfaceVariant,
              ),
            ),
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

