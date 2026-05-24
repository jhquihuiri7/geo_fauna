import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/user_avatar.dart';
import '../widgets/weather_header.dart';

/// Agenda — daily field logistics: weather, day strip, timeline (screens-main.jsx).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  // Nombres en español (sin dependencia de intl).
  static const _months = [
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
  static const _weekdayAbbr = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom', // 1=Lun … 7=Dom
  ];

  late final DateTime _today;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today;
  }

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
            leading: const UserAvatar(size: 40),
            trailing: [Icon(Icons.cloud_done, color: eco.primary)],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu Agenda',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1.5,
                    color: eco.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logística de campo para ${_selectedDateText(_selectedDate)}',
                  style: TextStyle(fontSize: 15, color: eco.onSurfaceVariant),
                ),
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
                  _dayCell(eco, _today.add(Duration(days: i))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _timeline(context, eco, _selectedDate),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(AppColors eco, DateTime date) {
    final active = _sameDay(date, _selectedDate);
    final label = _sameDay(date, _today)
        ? 'Hoy'
        : _weekdayAbbr[date.weekday - 1];

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: active ? eco.primaryContainer : eco.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: (active ? eco.onPrimaryContainer : eco.onSurface)
                    .withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: active ? eco.onPrimaryContainer : eco.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(BuildContext context, AppColors eco, DateTime selectedDate) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, eventSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('tours').snapshots(),
          builder: (context, tourSnap) {
            if (_isLoading(eventSnap) || _isLoading(tourSnap)) {
              return _loadingTimeline(eco);
            }
            if (eventSnap.hasError || tourSnap.hasError) {
              return _timelineError(eco, eventSnap.error ?? tourSnap.error!);
            }

            final items =
                [
                    for (final doc
                        in eventSnap.data?.docs ??
                            const <
                              QueryDocumentSnapshot<Map<String, dynamic>>
                            >[])
                      _AgendaItem.fromEvent(doc.id, doc.data()),
                    for (final doc
                        in tourSnap.data?.docs ??
                            const <
                              QueryDocumentSnapshot<Map<String, dynamic>>
                            >[])
                      _AgendaItem.fromTour(doc.id, doc.data()),
                  ].where((item) => _sameDay(item.date, selectedDate)).toList()
                  ..sort((a, b) {
                    final aTime = a.startAt ?? a.date;
                    final bTime = b.startAt ?? b.date;
                    return aTime.compareTo(bTime);
                  });

            if (items.isEmpty) return _emptyTimeline(eco, selectedDate);

            return Column(
              children: [
                for (final entry in items.asMap().entries)
                  Padding(
                    padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 12),
                    child: _activityCard(eco, entry.value),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isLoading(AsyncSnapshot snap) {
    return snap.connectionState == ConnectionState.waiting && !snap.hasData;
  }

  Widget _loadingTimeline(AppColors eco) {
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            'Cargando actividades...',
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

  Widget _timelineError(AppColors eco, Object error) {
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: eco.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No se pudieron cargar las actividades: $error',
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

  Widget _emptyTimeline(AppColors eco, DateTime selectedDate) {
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
          Text(
            _sameDay(selectedDate, _today)
                ? 'Sin actividades para hoy'
                : 'Sin actividades para este día',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: eco.onSurface,
            ),
          ),
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

  Widget _activityCard(AppColors eco, _AgendaItem item) {
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: eco.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: eco.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    EcoChip(item.kindLabel, tone: item.chipTone, small: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.timeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: eco.primary,
                  ),
                ),
                if (item.locationLabel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: eco.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.locationLabel!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: eco.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.body != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.body!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
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

  String _selectedDateText(DateTime date) {
    if (_sameDay(date, _today)) {
      return 'hoy, ${date.day} de ${_months[date.month - 1]}';
    }
    return '${_weekdayAbbr[date.weekday - 1].toLowerCase()}, '
        '${date.day} de ${_months[date.month - 1]}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _AgendaItem {
  const _AgendaItem({
    required this.id,
    required this.title,
    required this.date,
    required this.kindLabel,
    required this.icon,
    required this.chipTone,
    this.startAt,
    this.endAt,
    this.locationLabel,
    this.body,
  });

  final String id;
  final String title;
  final DateTime date;
  final DateTime? startAt;
  final DateTime? endAt;
  final String kindLabel;
  final IconData icon;
  final ChipTone chipTone;
  final String? locationLabel;
  final String? body;

  String get timeLabel {
    if (startAt == null) return 'Sin hora definida';
    if (endAt == null) return _formatTime(startAt!);
    return '${_formatTime(startAt!)} - ${_formatTime(endAt!)}';
  }

  factory _AgendaItem.fromEvent(String id, Map<String, dynamic> data) {
    final startAt = _toDate(data['startAt']);
    final date = startAt ?? _toDate(data['date']) ?? DateTime(1900);
    final type = _stringValue(data['type']);
    return _AgendaItem(
      id: id,
      title:
          _firstNonEmpty([
            _stringValue(data['title']),
            _stringValue(data['name']),
          ]) ??
          'Evento sin título',
      date: date,
      startAt: startAt,
      endAt: _toDate(data['endAt']),
      kindLabel: _eventTypeLabel(type),
      icon: _eventIcon(type),
      chipTone: ChipTone.tertiary,
      locationLabel: _firstNonEmpty([
        _stringValue(data['locationLabel']),
        _stringValue(data['meetingPoint']),
        _stringValue(data['placeName']),
      ]),
      body: _firstNonEmpty([
        _stringValue(data['objectives']),
        _stringValue(data['description']),
        _stringValue(data['body']),
      ]),
    );
  }

  factory _AgendaItem.fromTour(String id, Map<String, dynamic> data) {
    final startAt = _toDate(data['startAt']);
    final date = startAt ?? _toDate(data['date']) ?? DateTime(1900);
    final type = _stringValue(data['type']);
    return _AgendaItem(
      id: id,
      title:
          _firstNonEmpty([
            _stringValue(data['name']),
            _stringValue(data['title']),
          ]) ??
          'Tour sin nombre',
      date: date,
      startAt: startAt,
      endAt: _toDate(data['endAt']),
      kindLabel: _tourTypeLabel(type),
      icon: Icons.route,
      chipTone: ChipTone.emerald,
      locationLabel: _firstNonEmpty([
        _stringValue(data['meetingPoint']),
        _stringValue(data['locationLabel']),
        _stringValue(data['placeName']),
      ]),
      body: _firstNonEmpty([
        _stringValue(data['description']),
        _stringValue(data['notes']),
      ]),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _eventTypeLabel(String? type) {
  return switch ((type ?? '').toLowerCase()) {
    'mission' || 'misión' => 'Misión',
    'workshop' || 'taller' => 'Taller',
    'cleanup' || 'limpieza' => 'Limpieza',
    _ => 'Evento',
  };
}

IconData _eventIcon(String? type) {
  return switch ((type ?? '').toLowerCase()) {
    'cleanup' || 'limpieza' => Icons.cleaning_services,
    'workshop' || 'taller' => Icons.groups,
    'mission' || 'misión' => Icons.science,
    _ => Icons.event,
  };
}

String _tourTypeLabel(String? type) {
  return switch ((type ?? '').toLowerCase()) {
    'marine' || 'marino' => 'Marino',
    'terrestrial' || 'terrestre' => 'Terrestre',
    'sighting' || 'avistamiento' => 'Avistamiento',
    'educational' || 'educativo' => 'Educativo',
    'day_tour' || 'tour diario' => 'Tour',
    'cruise' || 'crucero' => 'Crucero',
    _ => 'Tour',
  };
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    final parts = value.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      final c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        if (parts[0].length == 4) return DateTime(a, b, c);
        return DateTime(c, b, a);
      }
    }
  }
  return null;
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  return value.toString();
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
