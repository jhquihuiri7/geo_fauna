import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';
import '../services/field_data_service.dart';
import '../services/offline_sync_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_colors.dart';
import 'tracking_screen.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/route_map.dart';
import '../widgets/user_avatar.dart';
import '../widgets/weather_header.dart';

/// Agenda — daily field logistics: weather, day strip, timeline (screens-main.jsx).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _dataService = FieldDataService();

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
                AgendaWeatherCard(selectedDate: _selectedDate),
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
                for (var i = 0; i < 15; i++)
                  _dayCell(eco, _today.add(Duration(days: i))),
              ],
            ),
          ),
          _activeTrackBanner(context, eco),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _timeline(context, eco, _selectedDate),
          ),
        ],
      ),
    );
  }

  /// Banner persistente cuando hay un recorrido activo o recuperado, para
  /// volver a la pantalla de grabación o reanudarlo.
  Widget _activeTrackBanner(BuildContext context, AppColors eco) {
    return ValueListenableBuilder<TrackingSession?>(
      valueListenable: TrackingService.instance.session,
      builder: (context, session, _) {
        if (session == null) return const SizedBox.shrink();
        final recording = session.isRecording;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrackingScreen(
                    tourId: session.tourId,
                    tourName: session.tourName,
                    tourType: session.tourType,
                    resume: !recording,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: eco.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: eco.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    recording
                        ? Icons.fiber_manual_record_rounded
                        : Icons.pause_circle_filled_rounded,
                    color: recording ? eco.error : eco.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording
                              ? 'Recorrido en curso'
                              : 'Recorrido en pausa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: eco.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.tourName ?? 'Recorrido libre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: eco.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    recording ? 'Abrir' : 'Reanudar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: eco.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: eco.primary),
                ],
              ),
            ),
          ),
        );
      },
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
    return ValueListenableBuilder<List<OfflineSyncOperation>>(
      valueListenable: OfflineSyncService.instance.operations,
      builder: (context, offlineOperations, _) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, eventSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('tours')
                  .snapshots(),
              builder: (context, tourSnap) {
                if (_isLoading(eventSnap) || _isLoading(tourSnap)) {
                  return _loadingTimeline(eco);
                }
                if (eventSnap.hasError || tourSnap.hasError) {
                  return _timelineError(
                    eco,
                    eventSnap.error ?? tourSnap.error!,
                  );
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
                          ..._offlineAgendaItems(offlineOperations),
                        ]
                        .where((item) => _sameDay(item.date, selectedDate))
                        .toList()
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
                        child: _activityCard(context, eco, entry.value),
                      ),
                  ],
                );
              },
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

  Widget _activityCard(BuildContext context, AppColors eco, _AgendaItem item) {
    final canEdit =
        !item.pendingSync && item.ownerId == AuthService().currentUser?.uid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openAgendaDetail(context, item),
      child: EcoCard(
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
                      if (canEdit)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Editar',
                          onPressed: () => _openAgendaEditor(context, item),
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: eco.primary,
                          ),
                        ),
                      if (item.pendingSync)
                        const EcoChip(
                          'Sin sincronizar',
                          tone: ChipTone.warning,
                          small: true,
                        ),
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
      ),
    );
  }

  Future<void> _openAgendaDetail(BuildContext context, _AgendaItem item) async {
    final action = await showModalBottomSheet<_AgendaDetailAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.eco.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _AgendaDetailSheet(item: item),
    );
    if (!context.mounted) return;
    if (action == _AgendaDetailAction.edit) {
      await _openAgendaEditor(context, item);
    } else if (action == _AgendaDetailAction.startTracking) {
      // Si el tour ya tiene un recorrido grabado, confirmamos antes de
      // sobrescribirlo (se reutiliza el mismo trackId al volver a grabar).
      String? overwriteTrackId;
      if (item.trackId != null) {
        final overwrite = await _confirmOverwriteTrack(context);
        if (overwrite != true) return;
        overwriteTrackId = item.trackId;
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackingScreen(
            tourId: item.kind == _AgendaItemKind.tour ? item.id : null,
            tourName: item.title,
            tourType: item.type,
            overwriteTrackId: overwriteTrackId,
          ),
        ),
      );
    }
  }

  Future<bool?> _confirmOverwriteTrack(BuildContext context) {
    final eco = context.eco;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sobrescribir recorrido'),
        content: const Text(
          'Este tour ya tiene un recorrido grabado. Si vuelves a grabar, se '
          'reemplazará el recorrido anterior. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: eco.primary),
            child: const Text('Sobrescribir'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAgendaEditor(BuildContext context, _AgendaItem item) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.eco.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _AgendaEditSheet(item: item, dataService: _dataService),
    );
    if (!context.mounted || saved != true) return;
    _showAgendaSnack(context, '${item.kindLabel} actualizado correctamente.');
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
    required this.kind,
    required this.title,
    required this.date,
    required this.kindLabel,
    required this.icon,
    required this.chipTone,
    required this.type,
    this.ownerId,
    this.pendingSync = false,
    this.startAt,
    this.endAt,
    this.locationLabel,
    this.body,
    this.isPublic = true,
    this.participantCount = 0,
    this.capacity,
    this.trackId,
  });

  final String id;
  final _AgendaItemKind kind;
  final String title;
  final DateTime date;
  final DateTime? startAt;
  final DateTime? endAt;
  final String kindLabel;
  final IconData icon;
  final ChipTone chipTone;
  final String type;
  final String? ownerId;
  final bool pendingSync;
  final String? locationLabel;
  final String? body;
  final bool isPublic;
  final int participantCount;

  /// Cupo máximo del evento (null = sin límite).
  final int? capacity;

  /// Id del recorrido grabado asociado a un tour, si existe.
  final String? trackId;

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
      kind: _AgendaItemKind.event,
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
      type: type ?? 'Mision',
      ownerId: _firstNonEmpty([
        _stringValue(data['authorId']),
        _stringValue(data['createdBy']),
      ]),
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
      isPublic: data['isPublic'] != false && data['public'] != false,
      participantCount: _toInt(data['participantCount']) ?? 0,
      capacity: _toInt(data['capacity']),
    );
  }

  factory _AgendaItem.fromTour(String id, Map<String, dynamic> data) {
    final startAt = _toDate(data['startAt']);
    final date = startAt ?? _toDate(data['date']) ?? DateTime(1900);
    final type = _stringValue(data['type']);
    return _AgendaItem(
      id: id,
      kind: _AgendaItemKind.tour,
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
      type: type ?? 'Terrestre',
      ownerId: _firstNonEmpty([
        _stringValue(data['authorId']),
        _stringValue(data['createdBy']),
      ]),
      locationLabel: _firstNonEmpty([
        _stringValue(data['meetingPoint']),
        _stringValue(data['locationLabel']),
        _stringValue(data['placeName']),
      ]),
      body: _firstNonEmpty([
        _stringValue(data['description']),
        _stringValue(data['notes']),
      ]),
      trackId: _stringValue(data['trackId']),
    );
  }
}

enum _AgendaItemKind { event, tour }

enum _AgendaDetailAction { edit, startTracking }

class _AgendaDetailSheet extends StatelessWidget {
  const _AgendaDetailSheet({required this.item});

  final _AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final canEdit =
        !item.pendingSync && item.ownerId == AuthService().currentUser?.uid;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: eco.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          EcoChip(
                            item.kindLabel,
                            tone: item.chipTone,
                            small: true,
                          ),
                          if (item.pendingSync)
                            const EcoChip(
                              'Sin sincronizar',
                              tone: ChipTone.warning,
                              small: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: eco.outline),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _detailRow(
              eco,
              icon: Icons.schedule_rounded,
              label: 'Horario',
              value: item.timeLabel,
            ),
            if (item.locationLabel != null)
              _detailRow(
                eco,
                icon: Icons.location_on_rounded,
                label: 'Punto de encuentro',
                value: item.locationLabel!,
              ),
            _detailRow(
              eco,
              icon: Icons.category_rounded,
              label: 'Tipo',
              value: item.type,
            ),
            if (item.kind == _AgendaItemKind.event)
              _detailRow(
                eco,
                icon: Icons.groups_rounded,
                label: 'Participantes',
                value: item.capacity != null && item.capacity! > 0
                    ? '${item.participantCount}/${item.capacity} inscritos'
                    : '${item.participantCount} inscritos',
              ),
            if (item.body != null) ...[
              const SizedBox(height: 14),
              Text(
                item.kind == _AgendaItemKind.event ? 'OBJETIVOS' : 'NOTAS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: eco.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.body!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: eco.onSurface,
                ),
              ),
            ],
            if (item.kind == _AgendaItemKind.tour) ...[
              const SizedBox(height: 18),
              Text(
                'RECORRIDO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: eco.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _TourRouteSection(tourId: item.id),
            ],
            const SizedBox(height: 22),
            GradientButton(
              label: item.trackId != null
                  ? 'Volver a grabar recorrido'
                  : 'Iniciar recorrido',
              icon: Icons.my_location_rounded,
              onPressed: item.pendingSync
                  ? null
                  : () => Navigator.pop(
                      context,
                      _AgendaDetailAction.startTracking,
                    ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, _AgendaDetailAction.edit),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    AppColors eco, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: eco.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: eco.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: eco.onSurface,
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

/// Muestra el mapa del recorrido grabado para un tour. Si todavía no hay
/// recorrido, despliega un estado vacío; al grabar uno, dibuja la ruta.
class _TourRouteSection extends StatelessWidget {
  const _TourRouteSection({required this.tourId});

  final String tourId;

  Future<List<LatLng>> _loadRoute() async {
    final snap = await FirebaseFirestore.instance
        .collection('tracks')
        .where('tourId', isEqualTo: tourId)
        .get();
    if (snap.docs.isEmpty) return const [];

    // Sin orderBy para no exigir un índice compuesto: elegimos el más reciente
    // en cliente (normalmente solo hay uno, porque sobrescribir reutiliza el id).
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final aAt = _toDate(a.data()['endedAt']) ?? _toDate(a.data()['createdAt']);
        final bAt = _toDate(b.data()['endedAt']) ?? _toDate(b.data()['createdAt']);
        return (bAt ?? DateTime(1900)).compareTo(aAt ?? DateTime(1900));
      });
    return _pointsFromTrack(docs.first.data());
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return FutureBuilder<List<LatLng>>(
      future: _loadRoute(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _frame(
            eco,
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: eco.primary),
            ),
          );
        }
        if (snap.hasError) {
          return _frame(
            eco,
            icon: Icons.cloud_off_rounded,
            message: 'No se pudo cargar el recorrido.',
          );
        }
        final points = snap.data ?? const <LatLng>[];
        if (points.isEmpty) {
          return _frame(
            eco,
            icon: Icons.map_outlined,
            message: 'Aún no se ha grabado un recorrido para este tour.',
          );
        }
        return RouteMapPreview(points: points, height: 220);
      },
    );
  }

  Widget _frame(AppColors eco, {IconData? icon, String? message, Widget? child}) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (child != null)
            child
          else if (icon != null)
            Icon(icon, color: eco.outline, size: 30),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: eco.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<LatLng> _pointsFromTrack(Map<String, dynamic> data) {
  final path = data['path'];
  if (path is List && path.isNotEmpty) {
    final result = <LatLng>[];
    for (final p in path) {
      if (p is! GeoPoint) continue;
      final point = _safeLatLng(p.latitude, p.longitude);
      if (point != null) result.add(point);
    }
    if (result.isNotEmpty) return result;
  }
  final points = data['points'];
  if (points is List) {
    final result = <LatLng>[];
    for (final p in points) {
      if (p is! Map) continue;
      final lat = p['lat'];
      final lng = p['lng'];
      if (lat is! num || lng is! num) continue;
      final point = _safeLatLng(lat.toDouble(), lng.toDouble());
      if (point != null) result.add(point);
    }
    return result;
  }
  return const [];
}

/// Crea un LatLng solo si las coordenadas son finitas y están en rango; evita
/// "LatLng is not finite" por datos GPS corruptos.
LatLng? _safeLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return LatLng(lat, lng);
}

List<_AgendaItem> _offlineAgendaItems(List<OfflineSyncOperation> operations) {
  final uid = AuthService().currentUser?.uid;
  return [
    for (final operation in operations)
      if (operation.type == 'createTour')
        _AgendaItem(
          id: operation.id,
          kind: _AgendaItemKind.tour,
          title: _stringValue(operation.payload['name']) ?? 'Tour sin nombre',
          date: _dateFromMs(operation.payload['startAtMs']),
          startAt: _dateFromMs(operation.payload['startAtMs']),
          endAt: _dateFromMs(operation.payload['endAtMs']),
          kindLabel: 'Tour',
          icon: Icons.route,
          chipTone: ChipTone.emerald,
          type: _stringValue(operation.payload['type']) ?? 'Terrestre',
          ownerId: uid,
          locationLabel: _stringValue(operation.payload['meetingPoint']),
          body: _stringValue(operation.payload['notes']),
          pendingSync: true,
        )
      else if (operation.type == 'createEvent')
        _AgendaItem(
          id: operation.id,
          kind: _AgendaItemKind.event,
          title:
              _stringValue(operation.payload['title']) ?? 'Evento sin titulo',
          date: _dateFromMs(operation.payload['startAtMs']),
          startAt: _dateFromMs(operation.payload['startAtMs']),
          endAt: _dateFromMs(operation.payload['endAtMs']),
          kindLabel: _eventTypeLabel(_stringValue(operation.payload['type'])),
          icon: _eventIcon(_stringValue(operation.payload['type'])),
          chipTone: ChipTone.tertiary,
          type: _stringValue(operation.payload['type']) ?? 'Mision',
          ownerId: uid,
          locationLabel: _stringValue(operation.payload['meetingPoint']),
          body: _stringValue(operation.payload['objectives']),
          isPublic: operation.payload['isPublic'] != false,
          participantCount: 1,
          capacity: _toInt(operation.payload['capacity']),
          pendingSync: true,
        ),
  ];
}

class _AgendaEditSheet extends StatefulWidget {
  const _AgendaEditSheet({required this.item, required this.dataService});

  final _AgendaItem item;
  final FieldDataService dataService;

  @override
  State<_AgendaEditSheet> createState() => _AgendaEditSheetState();
}

class _AgendaEditSheetState extends State<_AgendaEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _meetingPointController;
  late String _type;
  late bool _isPublic;
  late int _capacity;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _saving = false;

  bool get _isEvent => widget.item.kind == _AgendaItemKind.event;

  @override
  void initState() {
    super.initState();
    final startAt = widget.item.startAt ?? widget.item.date;
    final endAt = widget.item.endAt ?? startAt.add(const Duration(hours: 1));
    _titleController = TextEditingController(text: widget.item.title);
    _bodyController = TextEditingController(text: widget.item.body ?? '');
    _meetingPointController = TextEditingController(
      text: widget.item.locationLabel ?? '',
    );
    _type = widget.item.type;
    _isPublic = widget.item.isPublic;
    _capacity = widget.item.capacity ?? 0;
    _date = DateTime(startAt.year, startAt.month, startAt.day);
    _startTime = TimeOfDay.fromDateTime(startAt);
    _endTime = TimeOfDay.fromDateTime(endAt);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _meetingPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: eco.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEvent ? 'Editar evento' : 'Editar agenda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: eco.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: eco.outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sheetField(
                eco,
                _isEvent ? 'Titulo' : 'Nombre',
                _textInput(
                  eco,
                  controller: _titleController,
                  hint: _isEvent ? 'Titulo del evento' : 'Nombre del tour',
                ),
              ),
              const SizedBox(height: 14),
              _sheetField(eco, 'Tipo', _typePicker(eco)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _datePicker(eco)),
                  const SizedBox(width: 12),
                  Expanded(child: _timePicker(eco, start: true)),
                ],
              ),
              const SizedBox(height: 14),
              _timePicker(eco, start: false),
              const SizedBox(height: 14),
              _sheetField(
                eco,
                'Punto de encuentro',
                _textInput(
                  eco,
                  controller: _meetingPointController,
                  hint: 'Lugar de encuentro',
                ),
              ),
              const SizedBox(height: 14),
              _sheetField(
                eco,
                _isEvent ? 'Objetivos' : 'Notas',
                _textInput(
                  eco,
                  controller: _bodyController,
                  hint: _isEvent ? 'Objetivos del evento' : 'Notas del tour',
                  maxLines: 3,
                ),
              ),
              if (_isEvent) ...[
                const SizedBox(height: 14),
                _publicSwitch(eco),
                const SizedBox(height: 14),
                _participantCounter(eco),
              ],
              const SizedBox(height: 22),
              GradientButton(
                label: _saving ? 'Guardando...' : 'Guardar cambios',
                icon: Icons.save_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(AppColors eco, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: eco.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _textInput(
    AppColors eco, {
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(maxLines > 1 ? 22 : 999),
      ),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        style: TextStyle(fontSize: 14, color: eco.onSurface),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: eco.outline, fontSize: 14),
        ),
      ),
    );
  }

  Widget _typePicker(AppColors eco) {
    final options = _isEvent
        ? const ['Mision', 'Taller', 'Limpieza']
        : const [
            'Marino',
            'Terrestre',
            'Avistamiento',
            'Educativo',
            'Tour diario',
            'Crucero',
          ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option),
            selected: _sameOption(_type, option),
            onSelected: _saving ? null : (_) => setState(() => _type = option),
            selectedColor: eco.primary.withValues(alpha: 0.16),
            labelStyle: TextStyle(
              color: _sameOption(_type, option) ? eco.primary : eco.onSurface,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: _sameOption(_type, option)
                  ? eco.primary
                  : eco.outlineVariant,
            ),
          ),
      ],
    );
  }

  Widget _datePicker(AppColors eco) {
    return _pickerTile(
      eco,
      label: 'Fecha',
      value: _formatAgendaDate(_date),
      icon: Icons.event_rounded,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(DateTime.now().year - 2, 1, 1),
          lastDate: DateTime(DateTime.now().year + 5, 12, 31),
        );
        if (picked != null) setState(() => _date = picked);
      },
    );
  }

  Widget _timePicker(AppColors eco, {required bool start}) {
    final value = start ? _startTime : _endTime;
    return _pickerTile(
      eco,
      label: start ? 'Inicio' : 'Fin',
      value: _formatTimeOfDay(value),
      icon: start ? Icons.schedule_rounded : Icons.timer_rounded,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value,
        );
        if (picked == null) return;
        setState(() {
          if (start) {
            _startTime = picked;
          } else {
            _endTime = picked;
          }
        });
      },
    );
  }

  Widget _pickerTile(
    AppColors eco, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: _saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: eco.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(icon, color: eco.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: eco.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _publicSwitch(AppColors eco) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_rounded, color: eco.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Visibilidad publica',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: eco.onSurface,
              ),
            ),
          ),
          EcoSwitch(
            value: _isPublic,
            onChanged: _saving
                ? (_) {}
                : (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
    );
  }

  Widget _participantCounter(AppColors eco) {
    final enrolled = widget.item.participantCount;
    // El cupo no puede bajar de los ya inscritos (el servidor también valida).
    final canDecrease = !_saving && _capacity > enrolled && _capacity > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cupo máximo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _capacity == 0 ? 'Sin límite' : '$enrolled inscritos',
                      style: TextStyle(
                        fontSize: 12,
                        color: eco.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: canDecrease
                    ? () => setState(() => _capacity--)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  _capacity == 0 ? '∞' : '$_capacity',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: eco.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => setState(() => _capacity++),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showAgendaSnack(
        context,
        _isEvent ? 'Ingresa el titulo.' : 'Ingresa el nombre.',
        error: true,
      );
      return;
    }

    final startAt = _combineAgendaDateAndTime(_date, _startTime);
    final endAt = _combineAgendaDateAndTime(_date, _endTime);
    if (!endAt.isAfter(startAt)) {
      _showAgendaSnack(
        context,
        'La hora fin debe ser posterior al inicio.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEvent) {
        await widget.dataService.updateEvent(
          eventId: widget.item.id,
          title: title,
          type: _type,
          startAt: startAt,
          endAt: endAt,
          isPublic: _isPublic,
          capacity: _capacity,
          objectives: _bodyController.text,
          meetingPoint: _meetingPointController.text,
        );
      } else {
        await widget.dataService.updateTour(
          tourId: widget.item.id,
          name: title,
          type: _type,
          startAt: startAt,
          endAt: endAt,
          notes: _bodyController.text,
          meetingPoint: _meetingPointController.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showAgendaSnack(context, 'No se pudo guardar: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatTimeOfDay(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _formatAgendaDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

DateTime _combineAgendaDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

bool _sameOption(String a, String b) {
  return a.trim().toLowerCase() == b.trim().toLowerCase();
}

void _showAgendaSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  if (!context.mounted) return;
  final eco = context.eco;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? eco.error : eco.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
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

DateTime _dateFromMs(Object? value) {
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.round());
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
  }
  return DateTime(1900);
}

String? _stringValue(Object? value) {
  if (value == null) return null;
  return value.toString();
}

int? _toInt(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
