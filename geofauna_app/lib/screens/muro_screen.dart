import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';

import '../services/auth_service.dart';
import '../services/calendar_service.dart';
import '../services/field_data_service.dart';
import '../services/wall_interaction_service.dart';
import '../services/wall_media_cache_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/route_map.dart';
import '../widgets/user_avatar.dart';

final _wallOptimism = _WallOptimism();

/// Color del "me gusta" (corazon) en el muro.
const _likeColor = Color(0xFFE0556B);

/// Muro — community wall with upcoming events + sighting feed.
class MuroScreen extends StatefulWidget {
  const MuroScreen({super.key, this.highlightSourceKey});

  final String? highlightSourceKey;

  @override
  State<MuroScreen> createState() => _MuroScreenState();
}

class _MuroScreenState extends State<MuroScreen> {
  String _filter = 'Recientes';

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      color: eco.bg,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          EcoTopBar(
            large: true,
            title: 'EcoGuía',
            leading: const UserAvatar(size: 42, status: AvatarStatus.on),
            subtitle: _userStatsSubtitle(),
            trailing: [
              CircleIconButton(icon: Icons.notifications, onTap: () {}),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Kicker('Eventos Próximos'),
                const SizedBox(height: 12),
              ],
            ),
          ),
          _eventsSection(eco),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'MURO DE AVISTAMIENTOS',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        for (final f in ['Recientes', 'Populares'])
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: Column(
                                children: [
                                  Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _filter == f
                                          ? eco.primary
                                          : eco.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_filter == f)
                                    Container(
                                      width: 18,
                                      height: 2,
                                      color: eco.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _feedSection(eco),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userStatsSubtitle() {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('userStats')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final xp = _toInt(data?['xp']) ?? 0;
        final streak = _toInt(data?['streakDays']) ?? 0;
        if (xp == 0 && streak == 0) return const SizedBox.shrink();

        final parts = [
          if (streak > 0) '$streak días',
          if (xp > 0) '${_formatInt(xp)} XP',
        ];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 12,
              color: Color(0xFFF97316),
            ),
            const SizedBox(width: 4),
            Text(parts.join(' · ')),
          ],
        );
      },
    );
  }

  Widget _eventsSection(AppColors eco) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snap) {
        if (_isLoading(snap)) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _loadingCard(eco, 'Cargando eventos...'),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _errorCard(
              eco,
              'No se pudieron cargar los eventos: ${snap.error}',
            ),
          );
        }

        final now = DateTime.now();
        final events =
            (snap.data?.docs ?? const [])
                .map((doc) => _WallEvent.fromMap(doc.id, doc.data()))
                .where((event) {
                  if (!event.visibleOnWall) return false;
                  if (event.date == null) return false;
                  if (_isClosedStatus(event.status)) return false;
                  return !event.date!.isBefore(
                    DateTime(now.year, now.month, now.day),
                  );
                })
                .toList()
              ..sort((a, b) => a.date!.compareTo(b.date!));

        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _emptyCard(
              eco,
              icon: Icons.event_busy,
              title: 'Sin eventos próximos',
              message: 'Los eventos publicados aparecerán en esta sección.',
            ),
          );
        }

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: events.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => _EventCard(event: events[index]),
          ),
        );
      },
    );
  }

  Widget _feedSection(AppColors eco) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('publicFeed').snapshots(),
      builder: (context, feedSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('fieldRecords')
              .snapshots(),
          builder: (context, recordsSnap) {
            if (_isLoading(feedSnap) || _isLoading(recordsSnap)) {
              return _loadingCard(eco, 'Cargando muro...');
            }
            if (feedSnap.hasError || recordsSnap.hasError) {
              return _errorCard(
                eco,
                'No se pudo cargar el muro: '
                '${feedSnap.error ?? recordsSnap.error}',
              );
            }

            final items = <_FeedItem>[
              for (final doc in feedSnap.data?.docs ?? const [])
                _FeedItem.fromPublicFeed(doc.id, doc.data()),
              for (final doc in recordsSnap.data?.docs ?? const [])
                if (_recordBelongsOnWall(doc.data()))
                  _FeedItem.fromFieldRecord(doc.id, doc.data()),
            ];

            final unique = <String, _FeedItem>{};
            for (final item in items) {
              unique[item.sourceKey] = item;
            }

            final feed = unique.values.toList();
            if (_filter == 'Populares') {
              feed.sort((a, b) => b.popularity.compareTo(a.popularity));
            } else {
              feed.sort((a, b) {
                final aDate =
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bDate =
                    b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bDate.compareTo(aDate);
              });
            }
            final highlightSourceKey = widget.highlightSourceKey;
            if (highlightSourceKey != null) {
              feed.sort((a, b) {
                final aMatch = a.sourceKey == highlightSourceKey;
                final bMatch = b.sourceKey == highlightSourceKey;
                if (aMatch == bMatch) return 0;
                return aMatch ? -1 : 1;
              });
            }

            if (feed.isEmpty) {
              return _emptyCard(
                eco,
                icon: Icons.forum_outlined,
                title: 'Sin publicaciones reales',
                message:
                    'Cuando existan registros publicados en publicFeed o fieldRecords, aparecerán aquí.',
              );
            }

            final visibleFeed = feed.take(20).toList();
            _warmWallFeedMedia(visibleFeed);

            return Column(
              children: [
                for (final entry in visibleFeed.asMap().entries)
                  Padding(
                    padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 24),
                    child: _SightingCard(
                      item: entry.value,
                      highlighted: entry.value.sourceKey == highlightSourceKey,
                    ),
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

  void _warmWallFeedMedia(List<_FeedItem> feed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final urls = <String?>[
        for (final item in feed.take(8)) item.mediaUrl,
        for (final item in feed.take(8)) item.posterUrl,
        for (final item in feed.take(8)) item.authorPhotoUrl,
      ];
      WallMediaCacheService.instance.warm(urls);
    });
  }

  Widget _loadingCard(AppColors eco, String message) {
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
            message,
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

  Widget _errorCard(AppColors eco, String message) {
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: eco.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
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

  Widget _emptyCard(
    AppColors eco, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return EcoCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: eco.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: eco.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final _WallEvent event;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final chipText = [
      event.dateLabel,
      if (event.xpReward != null && event.xpReward! > 0)
        '+${event.xpReward} XP',
    ].join(' · ');

    return SizedBox(
      width: 268,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openEventDetail(context, event),
        child: EcoCard(
          soft: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EcoChip(chipText, tone: event.chipTone),
              const SizedBox(height: 16),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.4,
                  color: eco.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  event.body ?? event.locationLabel ?? 'Sin descripción',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: eco.onSurfaceVariant,
                  ),
                ),
              ),
              if (event.participantCount != null || event.capacity != null) ...[
                const SizedBox(height: 12),
                Text(
                  _participantsLabel(event),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: eco.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openEventDetail(BuildContext context, _WallEvent event) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.eco.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _EventDetailSheet(event: event),
  );
}

/// Hoja de detalle de un evento del muro. Muestra datos en vivo (conteo de
/// inscritos / cupo) y permite participar o cancelar la participación. Al
/// inscribirse, agenda el evento en el calendario del teléfono; al cancelar, lo
/// elimina.
class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({required this.event});

  final _WallEvent event;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  final _dataService = FieldDataService();
  bool _working = false;

  String get _eventId => widget.event.id;
  String? get _uid => AuthService().currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final uid = _uid;
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(_eventId)
            .snapshots(),
        builder: (context, eventSnap) {
          final data = eventSnap.data?.data();
          final event = data == null
              ? widget.event
              : _WallEvent.fromMap(_eventId, data);

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: uid == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                      .collection('events')
                      .doc(_eventId)
                      .collection('participants')
                      .doc(uid)
                      .snapshots(),
            builder: (context, partSnap) {
              final joined = partSnap.data?.exists ?? false;
              final calendarEventId = _stringValue(
                partSnap.data?.data()?['calendarEventId'],
              );
              return SingleChildScrollView(
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
                    _header(eco, event),
                    const SizedBox(height: 18),
                    _detailRow(
                      eco,
                      icon: Icons.event_rounded,
                      label: 'Fecha y hora',
                      value: _scheduleLabel(event),
                    ),
                    if (event.locationLabel != null)
                      _detailRow(
                        eco,
                        icon: Icons.location_on_rounded,
                        label: 'Punto de encuentro',
                        value: event.locationLabel!,
                      ),
                    _detailRow(
                      eco,
                      icon: Icons.groups_rounded,
                      label: 'Participantes',
                      value: _participantsLabel(event),
                    ),
                    if (event.body != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'OBJETIVOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.body!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: eco.onSurface,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _actionButton(eco, event, joined, calendarEventId),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(AppColors eco, _WallEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: eco.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              EcoChip(event.type, tone: event.chipTone),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: eco.outline),
        ),
      ],
    );
  }

  Widget _actionButton(
    AppColors eco,
    _WallEvent event,
    bool joined,
    String? calendarEventId,
  ) {
    final uid = _uid;
    final isOwner = uid != null && uid == event.ownerId;

    if (isOwner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: eco.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, size: 18, color: eco.primary),
            const SizedBox(width: 8),
            Text(
              'Eres el organizador',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: eco.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (joined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _working ? null : () => _leave(calendarEventId),
          icon: _working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Icon(Icons.event_busy_rounded),
          label: Text(_working ? 'Cancelando...' : 'Cancelar participación'),
        ),
      );
    }

    final full = _isFull(event);
    return GradientButton(
      label: full
          ? 'Cupo lleno'
          : (_working ? 'Inscribiendo...' : 'Participar'),
      icon: full ? Icons.block_rounded : Icons.event_available_rounded,
      loading: _working,
      onPressed: (full || _working) ? null : () => _join(event),
    );
  }

  bool _isFull(_WallEvent event) {
    final capacity = event.capacity;
    final count = event.participantCount ?? 0;
    return capacity != null && capacity > 0 && count >= capacity;
  }

  ({DateTime start, DateTime end}) _calendarRange(_WallEvent event) {
    final start = event.startAt ?? event.date ?? DateTime.now();
    final end = event.endAt ?? start.add(const Duration(hours: 1));
    return (start: start, end: end);
  }

  Future<void> _join(_WallEvent event) async {
    if (_uid == null) return;
    setState(() => _working = true);
    String? calendarEventId;
    try {
      // Agendamos primero en el calendario para guardar su id junto a la
      // inscripción; si el cupo está lleno hacemos rollback del calendario.
      final range = _calendarRange(event);
      calendarEventId = await CalendarService.instance.addEvent(
        title: event.title,
        start: range.start,
        end: range.end,
        description: event.body,
        location: event.locationLabel,
      );

      final result = await _dataService.joinEvent(
        eventId: _eventId,
        calendarEventId: calendarEventId,
      );

      if (!mounted) return;
      if (result.full) {
        if (calendarEventId != null) {
          await CalendarService.instance.removeEvent(calendarEventId);
        }
        if (!mounted) return;
        _showEditorSnack(
          context,
          'El cupo del evento está completo.',
          error: true,
        );
        return;
      }
      _showEditorSnack(
        context,
        result.alreadyJoined
            ? 'Ya estabas inscrito en este evento.'
            : 'Te inscribiste. El evento se agregó a tu calendario.',
      );
    } catch (error) {
      if (calendarEventId != null) {
        await CalendarService.instance.removeEvent(calendarEventId);
      }
      if (mounted) {
        _showEditorSnack(
          context,
          'No se pudo completar la inscripción: $error',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _leave(String? calendarEventId) async {
    if (_uid == null) return;
    setState(() => _working = true);
    try {
      await _dataService.leaveEvent(eventId: _eventId);
      if (calendarEventId != null) {
        await CalendarService.instance.removeEvent(calendarEventId);
      }
      if (mounted) {
        _showEditorSnack(context, 'Cancelaste tu participación.');
      }
    } catch (error) {
      if (mounted) {
        _showEditorSnack(
          context,
          'No se pudo cancelar la participación: $error',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
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

  String _scheduleLabel(_WallEvent event) {
    final start = event.startAt ?? event.date;
    if (start == null) return 'Sin fecha definida';
    final dateText = _shortDate(start);
    final startTime = _hhmm(start);
    final end = event.endAt;
    if (end == null) return '$dateText · $startTime';
    return '$dateText · $startTime - ${_hhmm(end)}';
  }

  String _hhmm(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _SightingCard extends StatelessWidget {
  const _SightingCard({required this.item, this.highlighted = false});

  final _FeedItem item;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final target = WallInteractionTarget.fromFeedItem(
      id: item.id,
      sourceKey: item.sourceKey,
    );
    final fieldRecordId = item.fieldRecordId;
    final canEdit =
        fieldRecordId != null &&
        item.authorId == AuthService().currentUser?.uid;
    return Container(
      decoration: BoxDecoration(
        color: eco.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(36),
        border: highlighted
            ? Border.all(color: eco.primary.withValues(alpha: 0.75), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.5)
                : eco.primary.withValues(alpha: 0.05),
            blurRadius: 45,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _authorAvatar(item),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.authorName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: eco.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _headerMeta(context, item),
                    ],
                  ),
                ),
                if (canEdit)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Editar',
                    onPressed: () =>
                        _openFieldRecordEditor(context, fieldRecordId),
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: eco.primary,
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.chipLabel != null)
                      EcoChip(item.chipLabel!, tone: item.chipTone),
                    if (item.rankLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.rankLabel!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: eco.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: eco.onSurface,
                  ),
                ),
                if (item.isRoute) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _openLocationMap(context, item),
                    child: RouteMapPreview(
                      points: item.routePoints!,
                      height: 220,
                    ),
                  ),
                ] else if (item.mediaUrl != null ||
                    item.photoLabel != null) ...[
                  const SizedBox(height: 16),
                  _media(context, item),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _InteractionBar(item: item, target: target),
          ),
        ],
      ),
    );
  }

  Widget _authorAvatar(_FeedItem item) {
    if (item.authorPhotoUrl != null) {
      return Container(
        width: 42,
        height: 42,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: _CachedNetworkMediaImage(
          url: item.authorPhotoUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
    return Avatar(name: item.authorName, tone: AvatarTone.forest, size: 42);
  }

  Widget _headerMeta(BuildContext context, _FeedItem item) {
    final eco = context.eco;
    final timeText = item.createdAt == null
        ? 'Sin fecha'
        : _relativeTime(item.createdAt!);
    return Row(
      children: [
        Flexible(
          child: Text(
            timeText,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: eco.onSurfaceVariant,
            ),
          ),
        ),
        if (item.placeLabel != null && !item.isRoute) ...[
          Text(
            ' · ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: eco.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: GestureDetector(
              onTap: item.hasMapLocation
                  ? () => _openLocationMap(context, item)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: item.hasMapLocation ? eco.primary : eco.outline,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      item.placeLabel!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: item.hasMapLocation
                            ? eco.primary
                            : eco.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _media(BuildContext context, _FeedItem item) {
    final mediaUrl = item.mediaUrl;
    if (mediaUrl != null && item.mediaType == _PostMediaType.image) {
      return _GeoMediaFrame(
        item: item,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: GestureDetector(
            onTap: () => _openMediaViewer(context, item),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: _CachedNetworkMediaImage(
                url: mediaUrl,
                fit: BoxFit.cover,
                fallbackLabel: item.photoLabel ?? 'IMAGEN NO DISPONIBLE',
                borderRadius: 28,
              ),
            ),
          ),
        ),
      );
    }

    if (mediaUrl != null && item.mediaType == _PostMediaType.video) {
      return _GeoMediaFrame(
        item: item,
        child: _VideoPostPreview(
          label: item.photoLabel ?? 'Video cargado',
          posterUrl: item.posterUrl,
          onTap: () => _openMediaViewer(context, item),
        ),
      );
    }

    return _GeoMediaFrame(
      item: item,
      child: PhotoPlaceholder(label: item.photoLabel!, borderRadius: 28),
    );
  }
}

class _GeoMediaFrame extends StatelessWidget {
  const _GeoMediaFrame({required this.item, required this.child});

  final _FeedItem item;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!item.hasMapLocation) return child;
    return Stack(
      children: [
        child,
        Positioned(
          left: 12,
          bottom: 12,
          child: _GeoChip(item: item, compact: false),
        ),
      ],
    );
  }
}

class _GeoChip extends StatelessWidget {
  const _GeoChip({required this.item, required this.compact});

  final _FeedItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final title = item.placeLabel ?? 'Ubicación guardada';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLocationMap(context, item),
        borderRadius: BorderRadius.circular(999),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: BoxConstraints(maxWidth: compact ? 280 : 250),
              padding: EdgeInsets.fromLTRB(10, 8, compact ? 14 : 12, 8),
              decoration: BoxDecoration(
                color: eco.glass,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: eco.primary.withValues(alpha: 0.28),
                              width: 2,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.pin_drop_rounded,
                          size: 21,
                          color: eco.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: eco.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (!compact)
                          Text(
                            'Ver en el mapa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: eco.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openFieldRecordEditor(
  BuildContext context,
  String recordId,
) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('fieldRecords')
        .doc(recordId)
        .get();
    if (!context.mounted) return;
    final data = snap.data();
    if (!snap.exists || data == null) {
      _showEditorSnack(context, 'No se encontro el registro.', error: true);
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.eco.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _FieldRecordEditSheet(recordId: recordId, data: data),
    );
    if (context.mounted && saved == true) {
      _showEditorSnack(context, 'Monitoreo actualizado correctamente.');
    }
  } catch (error) {
    if (context.mounted) {
      _showEditorSnack(
        context,
        'No se pudo abrir la edicion: $error',
        error: true,
      );
    }
  }
}

enum _EvidenceEditMode { keep, replace, remove }

enum _WallEvidenceChoice { cameraPhoto, galleryPhoto, galleryVideo }

class _FieldRecordEditSheet extends StatefulWidget {
  const _FieldRecordEditSheet({required this.recordId, required this.data});

  final String recordId;
  final Map<String, dynamic> data;

  @override
  State<_FieldRecordEditSheet> createState() => _FieldRecordEditSheetState();
}

class _FieldRecordEditSheetState extends State<_FieldRecordEditSheet> {
  final _dataService = FieldDataService();
  final _picker = ImagePicker();
  late final TextEditingController _speciesController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late String _category;
  late bool _publishToWall;
  late DateTime _recordDate;
  late TimeOfDay _recordTime;
  _EvidenceEditMode _evidenceMode = _EvidenceEditMode.keep;
  final List<EvidenceDraft> _newEvidence = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _speciesController = TextEditingController(
      text: _stringValue(widget.data['speciesName']) ?? '',
    );
    _quantityController = TextEditingController(
      text: '${_toInt(widget.data['quantity']) ?? 1}',
    );
    _notesController = TextEditingController(
      text: _stringValue(widget.data['notes']) ?? '',
    );
    _category = _fieldCategoryLabel(_stringValue(widget.data['category']));
    _publishToWall =
        widget.data['publishToWall'] == true ||
        _stringValue(widget.data['visibility']) == 'public';
    final observedAt = _toDate(widget.data['observedAt']) ?? DateTime.now();
    _recordDate = DateTime(observedAt.year, observedAt.month, observedAt.day);
    _recordTime = TimeOfDay.fromDateTime(observedAt);
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
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
                      'Editar monitoreo',
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
              _editorField(eco, 'Categoria', _categoryPicker(eco)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _datePicker(eco)),
                  const SizedBox(width: 12),
                  Expanded(child: _timePicker(eco)),
                ],
              ),
              const SizedBox(height: 14),
              _editorField(
                eco,
                'Especie',
                _textInput(
                  eco,
                  controller: _speciesController,
                  hint: 'Nombre de especie',
                ),
              ),
              const SizedBox(height: 14),
              _editorField(
                eco,
                'Cantidad',
                _textInput(
                  eco,
                  controller: _quantityController,
                  hint: 'Cantidad',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 14),
              _editorField(
                eco,
                'Notas',
                _textInput(
                  eco,
                  controller: _notesController,
                  hint: 'Observaciones',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 14),
              _publishSwitch(eco),
              const SizedBox(height: 14),
              _evidenceEditor(eco),
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

  Widget _editorField(AppColors eco, String label, Widget child) {
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
    TextInputType? keyboardType,
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
        keyboardType: keyboardType,
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

  Widget _categoryPicker(AppColors eco) {
    const options = ['Fauna', 'Incidente', 'Flora', 'Basura', 'Otro'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option),
            selected: _category == option,
            onSelected: _saving
                ? null
                : (_) => setState(() => _category = option),
            selectedColor: eco.primary.withValues(alpha: 0.16),
            labelStyle: TextStyle(
              color: _category == option ? eco.primary : eco.onSurface,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: _category == option ? eco.primary : eco.outlineVariant,
            ),
          ),
      ],
    );
  }

  Widget _datePicker(AppColors eco) {
    return _pickerTile(
      eco,
      label: 'Fecha',
      value: _formatEditorDate(_recordDate),
      icon: Icons.event_rounded,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _recordDate,
          firstDate: DateTime(DateTime.now().year - 2, 1, 1),
          lastDate: DateTime(DateTime.now().year + 5, 12, 31),
        );
        if (picked != null) setState(() => _recordDate = picked);
      },
    );
  }

  Widget _timePicker(AppColors eco) {
    return _pickerTile(
      eco,
      label: 'Hora',
      value: _formatEditorTime(_recordTime),
      icon: Icons.schedule_rounded,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _recordTime,
        );
        if (picked != null) setState(() => _recordTime = picked);
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

  Widget _publishSwitch(AppColors eco) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.forum_rounded, color: eco.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Publicar en muro',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: eco.onSurface,
              ),
            ),
          ),
          EcoSwitch(
            value: _publishToWall,
            onChanged: _saving
                ? (_) {}
                : (value) => setState(() => _publishToWall = value),
          ),
        ],
      ),
    );
  }

  Widget _evidenceEditor(AppColors eco) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.perm_media_rounded, color: eco.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _evidenceLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: eco.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (_newEvidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _newEvidence.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final evidence = _newEvidence[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: eco.surfaceContainerLowest,
                      child: evidence.type == EvidenceType.image
                          ? Image.file(
                              File(evidence.file.path),
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.videocam_rounded, color: eco.primary),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Reemplazar'),
                onPressed: _saving ? null : _pickEvidence,
              ),
              ActionChip(
                avatar: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Quitar'),
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _newEvidence.clear();
                        _evidenceMode = _EvidenceEditMode.remove;
                      }),
              ),
              if (_evidenceMode != _EvidenceEditMode.keep)
                ActionChip(
                  avatar: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Mantener actual'),
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _newEvidence.clear();
                          _evidenceMode = _EvidenceEditMode.keep;
                        }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _evidenceLabel() {
    if (_evidenceMode == _EvidenceEditMode.remove) return 'Sin evidencia';
    if (_newEvidence.isNotEmpty) {
      return '${_newEvidence.length} nueva(s) evidencia(s)';
    }
    final current = widget.data['evidence'];
    if (current is List && current.isNotEmpty) {
      return '${current.length} evidencia(s) actual(es)';
    }
    return 'Sin evidencia actual';
  }

  Future<void> _pickEvidence() async {
    final choice = await _wallEvidenceChoice(context);
    if (choice == null) return;
    XFile? file;
    EvidenceType type;
    if (choice == _WallEvidenceChoice.cameraPhoto) {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      type = EvidenceType.image;
    } else if (choice == _WallEvidenceChoice.galleryPhoto) {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      type = EvidenceType.image;
    } else {
      file = await _picker.pickVideo(source: ImageSource.gallery);
      type = EvidenceType.video;
    }
    if (file == null || !mounted) return;
    setState(() {
      _newEvidence.add(EvidenceDraft(file: file!, type: type));
      _evidenceMode = _EvidenceEditMode.replace;
    });
  }

  Future<void> _save() async {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showEditorSnack(context, 'Ingresa una cantidad valida.', error: true);
      return;
    }
    final observedAt = DateTime(
      _recordDate.year,
      _recordDate.month,
      _recordDate.day,
      _recordTime.hour,
      _recordTime.minute,
    );
    setState(() => _saving = true);
    try {
      await _dataService.updateFieldRecord(
        recordId: widget.recordId,
        category: _category,
        observedAt: observedAt,
        quantity: quantity,
        publishToWall: _publishToWall,
        replaceEvidence: _evidenceMode != _EvidenceEditMode.keep,
        evidence: _evidenceMode == _EvidenceEditMode.replace
            ? List.of(_newEvidence)
            : const [],
        speciesName: _speciesController.text,
        notes: _notesController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showEditorSnack(context, 'No se pudo guardar: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<_WallEvidenceChoice?> _wallEvidenceChoice(BuildContext context) {
  final eco = context.eco;
  return showModalBottomSheet<_WallEvidenceChoice>(
    context: context,
    backgroundColor: eco.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      Widget option({
        required IconData icon,
        required String title,
        required _WallEvidenceChoice value,
      }) {
        return ListTile(
          leading: Icon(icon, color: eco.primary),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: eco.onSurface),
          ),
          onTap: () => Navigator.pop(context, value),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              option(
                icon: Icons.photo_camera_rounded,
                title: 'Tomar foto',
                value: _WallEvidenceChoice.cameraPhoto,
              ),
              option(
                icon: Icons.photo_library_rounded,
                title: 'Elegir foto',
                value: _WallEvidenceChoice.galleryPhoto,
              ),
              option(
                icon: Icons.video_library_rounded,
                title: 'Elegir video',
                value: _WallEvidenceChoice.galleryVideo,
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _fieldCategoryLabel(String? value) {
  return switch ((value ?? '').toLowerCase()) {
    'fauna' => 'Fauna',
    'flora' => 'Flora',
    'incident' || 'incidente' => 'Incidente',
    'trash' || 'basura' => 'Basura',
    _ => 'Otro',
  };
}

String _formatEditorDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _formatEditorTime(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

void _showEditorSnack(
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

class _VideoPostPreview extends StatelessWidget {
  const _VideoPostPreview({
    required this.label,
    required this.onTap,
    this.posterUrl,
  });

  final String label;
  final VoidCallback onTap;
  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101412),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (posterUrl != null)
                  _CachedNetworkMediaImage(url: posterUrl!, fit: BoxFit.cover)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          eco.primary.withValues(alpha: 0.48),
                          const Color(0xFF101412),
                          eco.tertiary.withValues(alpha: 0.36),
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                  ),
                ),
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CachedNetworkMediaImage extends StatelessWidget {
  const _CachedNetworkMediaImage({
    required this.url,
    required this.fit,
    this.fallbackLabel,
    this.borderRadius = 0,
  });

  final String url;
  final BoxFit fit;
  final String? fallbackLabel;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cache = WallMediaCacheService.instance;
    return StreamBuilder<FileResponse>(
      stream: cache.fileStream(url),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data is FileInfo) {
          return Image.file(
            data.file,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stack) {
              if (fallbackLabel != null) {
                return PhotoPlaceholder(
                  label: fallbackLabel!,
                  borderRadius: borderRadius,
                );
              }
              return const SizedBox.shrink();
            },
          );
        }

        if (snapshot.hasError && fallbackLabel != null) {
          return PhotoPlaceholder(
            label: fallbackLabel!,
            borderRadius: borderRadius,
          );
        }

        return _MediaLoadingFrame(
          progress: data is DownloadProgress ? data.progress : null,
        );
      },
    );
  }
}

class _MediaLoadingFrame extends StatelessWidget {
  const _MediaLoadingFrame({this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final value = progress;
    return Container(
      color: eco.surfaceContainerLow,
      alignment: Alignment.center,
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          value: value != null && value > 0 && value < 1 ? value : null,
          strokeWidth: 2.6,
          color: eco.primary,
        ),
      ),
    );
  }
}

void _openMediaViewer(BuildContext context, _FeedItem item) {
  final mediaUrl = item.mediaUrl;
  final mediaType = item.mediaType;
  if (mediaUrl == null || mediaType == null) return;

  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _FullScreenMediaViewer(
            url: mediaUrl,
            type: mediaType,
            label: item.photoLabel,
          ),
        );
      },
    ),
  );
}

void _openLocationMap(BuildContext context, _FeedItem item) {
  if (!item.hasMapLocation) return;
  final eco = context.eco;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: eco.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _LocationMapSheet(item: item),
  );
}

class _LocationMapSheet extends StatelessWidget {
  const _LocationMapSheet({required this.item});

  final _FeedItem item;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final point = item.locationPoint;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: eco.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_rounded, color: eco.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DÓNDE SE REGISTRÓ',
                        style: TextStyle(
                          color: eco.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.placeLabel ?? 'Ubicación del monitoreo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: eco.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                  bg: eco.surfaceContainerLow,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sheetMap(context),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (point != null)
                  _MapMetaTile(
                    icon: Icons.explore_rounded,
                    label: 'Coordenadas',
                    value:
                        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                  ),
                _MapMetaTile(
                  icon: Icons.schedule_rounded,
                  label: 'Capturado',
                  value: item.createdAt == null
                      ? 'Sin fecha'
                      : _relativeTime(item.createdAt!),
                ),
                if (item.chipLabel != null)
                  _MapMetaTile(
                    icon: Icons.eco_rounded,
                    label: 'Categoría',
                    value: item.chipLabel!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetMap(BuildContext context) {
    final point = item.locationPoint;
    if (item.isRoute) {
      return RouteMapPreview(
        points: item.routePoints!,
        height: 300,
        borderRadius: 26,
        interactive: true,
      );
    }
    if (point == null) {
      return PhotoPlaceholder(
        label: 'SIN COORDENADAS',
        borderRadius: 26,
        aspectRatio: 16 / 10,
      );
    }
    final eco = context.eco;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geofauna.app',
              tileProvider: NetworkTileProvider(),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 54,
                  height: 64,
                  alignment: Alignment.topCenter,
                  child: _MapPinMarker(color: eco.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPinMarker extends StatelessWidget {
  const _MapPinMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
        ),
        CustomPaint(size: const Size(18, 12), painter: _PinTipPainter(color)),
      ],
    );
  }
}

class _PinTipPainter extends CustomPainter {
  const _PinTipPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _MapMetaTile extends StatelessWidget {
  const _MapMetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: eco.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: eco.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: eco.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenMediaViewer extends StatefulWidget {
  const _FullScreenMediaViewer({
    required this.url,
    required this.type,
    this.label,
  });

  final String url;
  final _PostMediaType type;
  final String? label;

  @override
  State<_FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<_FullScreenMediaViewer> {
  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.type == _PostMediaType.video
                  ? _FullScreenVideoPlayer(
                      url: widget.url,
                      label: widget.label ?? 'Video',
                    )
                  : InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Center(
                        child: _CachedNetworkMediaImage(
                          url: widget.url,
                          fit: BoxFit.contain,
                          fallbackLabel: widget.label ?? 'Imagen no disponible',
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _ViewerIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenVideoPlayer extends StatefulWidget {
  const _FullScreenVideoPlayer({required this.url, required this.label});

  final String url;
  final String label;

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _controlsVisible = true;
  bool _muted = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final file = await WallMediaCacheService.instance.getFile(widget.url);
      if (!mounted) return;
      final controller = VideoPlayerController.file(file)
        ..addListener(_onVideoTick);
      _controller = controller;
      await controller.initialize();
      if (!mounted) {
        if (identical(_controller, controller)) {
          _controller = null;
          await controller.dispose();
        }
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      _scheduleHideControls();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onVideoTick() {
    if (mounted && _ready) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller
        ..removeListener(_onVideoTick)
        ..dispose();
    }
    super.dispose();
  }

  void _toggleControls() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible && controller.value.isPlaying) {
      _scheduleHideControls();
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
      _hideTimer?.cancel();
      setState(() => _controlsVisible = true);
    } else {
      controller.play();
      setState(() => _controlsVisible = true);
      _scheduleHideControls();
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    _muted = !_muted;
    controller.setVolume(_muted ? 0 : 1);
    setState(() {});
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      final controller = _controller;
      if (!mounted || controller == null || !controller.value.isPlaying) {
        return;
      }
      setState(() => _controlsVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.videocam_off, color: Colors.white70, size: 46),
            SizedBox(height: 12),
            Text(
              'No se pudo reproducir el video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (!_ready || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final value = controller.value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio == 0 ? 9 / 16 : value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          AnimatedOpacity(
            opacity: _controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Stack(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Colors.transparent,
                          Color(0x99000000),
                        ],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayback,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: value.isPlaying ? 74 : 88,
                        height: value.isPlaying ? 74 : 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: value.isPlaying ? 34 : 48,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: _VideoControlDock(
                      controller: controller,
                      label: widget.label,
                      muted: _muted,
                      onPlayPause: _togglePlayback,
                      onMute: _toggleMute,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoControlDock extends StatelessWidget {
  const _VideoControlDock({
    required this.controller,
    required this.label,
    required this.muted,
    required this.onPlayPause,
    required this.onMute,
  });

  final VideoPlayerController controller;
  final String label;
  final bool muted;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _ViewerIconButton(
                icon: value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: onPlayPause,
                compact: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_formatVideoTime(value.position)} / '
                '${_formatVideoTime(value.duration)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              _ViewerIconButton(
                icon: muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: onMute,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white.withValues(alpha: 0.32),
              backgroundColor: Colors.white.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerIconButton extends StatelessWidget {
  const _ViewerIconButton({
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 44.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, color: Colors.white, size: compact ? 18 : 24),
      ),
    );
  }
}

String _formatVideoTime(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) return '$hours:$minutes:$seconds';
  return '$minutes:$seconds';
}

class _InteractionBar extends StatefulWidget {
  const _InteractionBar({required this.item, required this.target});

  final _FeedItem item;
  final WallInteractionTarget target;

  @override
  State<_InteractionBar> createState() => _InteractionBarState();
}

class _InteractionBarState extends State<_InteractionBar> {
  @override
  Widget build(BuildContext context) {
    final service = WallInteractionService.instance;
    return AnimatedBuilder(
      animation: _wallOptimism,
      builder: (context, _) {
        final commentCount = _wallOptimism.commentCount(
          widget.item,
          widget.target,
        );
        final pendingLike = _wallOptimism.like(widget.target);

        return StreamBuilder<bool>(
          stream: service.userLikeStream(widget.target),
          builder: (context, snap) {
            final liked = pendingLike?.liked ?? (snap.data ?? false);
            final reactionCounts =
                pendingLike?.counts ?? widget.item.reactionCounts;
            final likeCount = _sumMapCounts(reactionCounts);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionPill(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: likeCount > 0
                          ? '$likeCount Me gusta'
                          : 'Me gusta',
                      active: liked,
                      activeColor: _likeColor,
                      onTap: pendingLike == null
                          ? () => _toggleLike(liked, reactionCounts)
                          : null,
                    ),
                    _ActionPill(
                      icon: Icons.add_comment_rounded,
                      label: '$commentCount comentarios',
                      onTap: () =>
                          _openComments(context, widget.item, widget.target),
                    ),
                  ],
                ),
                if (likeCount > 0) ...[
                  const SizedBox(height: 12),
                  _ReactionSummary(
                    target: widget.target,
                    count: likeCount,
                    onOpen: () =>
                        _openReactors(context, widget.item, widget.target),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _toggleLike(bool liked, Map<String, int> reactionCounts) {
    _toggleLikeOptimistically(
      context,
      widget.target,
      currentlyLiked: liked,
      baseCounts: reactionCounts,
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    this.active = false,
    this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final color = activeColor ?? eco.primary;
    final bg = active ? color.withValues(alpha: 0.12) : eco.surfaceContainerLow;
    final fg = active ? color : eco.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: active
                  ? Border.all(color: color.withValues(alpha: 0.22))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: fg,
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

class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary({
    required this.target,
    required this.count,
    required this.onOpen,
  });

  final WallInteractionTarget target;
  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final eco = context.eco;

    return StreamBuilder<List<WallReaction>>(
      stream: WallInteractionService.instance.reactionsStream(target),
      builder: (context, snap) {
        final reactions = snap.data ?? const <WallReaction>[];
        final leading = reactions.isEmpty ? null : reactions.first;
        return InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              children: [
                if (leading != null)
                  _ReactionAvatar(reaction: leading, size: 26)
                else
                  const _LikeBubble(size: 24),
                const SizedBox(width: 9),
                Expanded(child: _likeText(eco, leading?.authorName)),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: eco.outline,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Texto estilo Instagram: "Le gusta a NOMBRE y N personas más", con los
  /// nombres en negrita. Si aún no cargó la lista, muestra solo el conteo.
  Widget _likeText(AppColors eco, String? name) {
    final normal = TextStyle(
      color: eco.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final bold = TextStyle(
      color: eco.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w900,
    );
    if (name == null) {
      return Text(
        '$count Me gusta',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: bold,
      );
    }
    final others = count - 1;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Le gusta a ', style: normal),
          TextSpan(text: name, style: bold),
          if (others > 0) ...[
            TextSpan(text: ' y ', style: normal),
            TextSpan(
              text: others == 1 ? '1 persona más' : '$others personas más',
              style: bold,
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _LikeBubble extends StatelessWidget {
  const _LikeBubble({this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: eco.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(color: eco.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        size: size * 0.56,
        color: _likeColor,
      ),
    );
  }
}

class _ReactionAvatar extends StatelessWidget {
  const _ReactionAvatar({required this.reaction, this.size = 26});

  final WallReaction reaction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = reaction.authorPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: _CachedNetworkMediaImage(url: photoUrl, fit: BoxFit.cover),
      );
    }
    return Avatar(name: reaction.authorName, tone: AvatarTone.slate, size: size);
  }
}

class _ReactorsSheet extends StatelessWidget {
  const _ReactorsSheet({required this.item, required this.target});

  final _FeedItem item;
  final WallInteractionTarget target;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<WallReaction>>(
                stream: WallInteractionService.instance.reactionsStream(target),
                builder: (context, snap) {
                  final reactions = snap.data ?? const <WallReaction>[];
                  final total = reactions.isEmpty
                      ? _sumMapCounts(item.reactionCounts)
                      : reactions.length;

                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Me gusta · $total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: eco.onSurface,
                                ),
                              ),
                            ),
                            CircleIconButton(
                              icon: Icons.close_rounded,
                              onTap: () => Navigator.pop(context),
                              bg: eco.surfaceContainerLow,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: _ReactorsList(
                            reactions: reactions,
                            loading:
                                snap.connectionState ==
                                    ConnectionState.waiting &&
                                !snap.hasData,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactorsList extends StatelessWidget {
  const _ReactorsList({required this.reactions, required this.loading});

  final List<WallReaction> reactions;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    if (loading) {
      return Center(child: CircularProgressIndicator(color: eco.primary));
    }
    if (reactions.isEmpty) {
      return Center(
        child: Text(
          'Aún no hay reacciones visibles.',
          style: TextStyle(
            color: eco.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: reactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reaction = reactions[index];
        return Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ReactionAvatar(reaction: reaction, size: 46),
                const Positioned(
                  right: -3,
                  bottom: -3,
                  child: _LikeBubble(size: 24),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reaction.authorName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: eco.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'le gusta',
                    style: TextStyle(
                      color: eco.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.item, required this.target});

  final _FeedItem item;
  final WallInteractionTarget target;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  late int _visibleCommentCount;

  @override
  void initState() {
    super.initState();
    _visibleCommentCount = widget.item.comments;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comentarios',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: eco.onSurface,
                      ),
                    ),
                  ),
                  EcoChip('$_visibleCommentCount', tone: ChipTone.slate),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<WallComment>>(
                  stream: WallInteractionService.instance.commentsStream(
                    widget.target,
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: eco.primary),
                      );
                    }
                    if (snap.hasError) {
                      return _sheetState(
                        eco,
                        icon: Icons.cloud_off,
                        title: 'No se pudieron cargar comentarios',
                        message: '${snap.error}',
                      );
                    }
                    final comments = snap.data ?? const <WallComment>[];
                    final visibleComments = _wallOptimism.commentsWithPending(
                      widget.target,
                      comments,
                    );
                    _scheduleCommentSync(comments, visibleComments.length);
                    if (visibleComments.isEmpty) {
                      return _sheetState(
                        eco,
                        icon: Icons.chat_bubble_outline,
                        title: 'Sin comentarios',
                        message: 'Se el primero en comentar esta publicacion.',
                      );
                    }
                    return ListView.separated(
                      itemCount: visibleComments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _CommentRow(comment: visibleComments[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: eco.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        style: TextStyle(color: eco.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Escribe un comentario...',
                          hintStyle: TextStyle(
                            color: eco.outline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleIconButton(
                      icon: Icons.send,
                      onTap: _send,
                      bg: eco.primary,
                      iconColor: eco.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    late final QueuedWallComment queued;
    try {
      queued = WallInteractionService.instance.queueComment(
        widget.target,
        text,
      );
    } catch (error) {
      _showWallError(context, error);
      return;
    }

    _controller.clear();
    _wallOptimism.addPendingComment(widget.target, queued.comment);
    setState(() => _visibleCommentCount += 1);

    unawaited(
      queued.commit
          .then((_) => Future<void>.delayed(const Duration(milliseconds: 500)))
          .then(
            (_) => _wallOptimism.removePendingComment(
              widget.target,
              queued.comment.id,
            ),
          )
          .catchError((Object error) {
            _wallOptimism.removePendingComment(
              widget.target,
              queued.comment.id,
            );
            if (!mounted) return;
            setState(() {
              if (_visibleCommentCount > 0) _visibleCommentCount -= 1;
            });
            _showWallError(context, error);
          }),
    );
  }

  void _scheduleCommentSync(
    List<WallComment> serverComments,
    int visibleCount,
  ) {
    if (_visibleCommentCount == visibleCount &&
        !_wallOptimism.hasPendingComments(widget.target)) {
      return;
    }

    final serverIds = serverComments.map((comment) => comment.id).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wallOptimism.removePendingComments(widget.target, serverIds);
      if (_visibleCommentCount != visibleCount) {
        setState(() => _visibleCommentCount = visibleCount);
      }
    });
  }

  Widget _sheetState(
    AppColors eco, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: eco.outline, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: eco.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: eco.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final WallComment comment;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Opacity(
      opacity: comment.isPending ? 0.72 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _commentAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: eco.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: eco.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (comment.createdAt != null)
                        Text(
                          _relativeTime(comment.createdAt!),
                          style: TextStyle(
                            color: eco.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.body,
                    style: TextStyle(
                      color: eco.onSurface,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentAvatar() {
    final photoUrl = comment.authorPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(photoUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Avatar(name: comment.authorName, tone: AvatarTone.teal, size: 34);
  }
}

void _toggleLikeOptimistically(
  BuildContext context,
  WallInteractionTarget target, {
  required bool currentlyLiked,
  required Map<String, int> baseCounts,
}) {
  final started = _wallOptimism.startLike(
    target,
    currentlyLiked: currentlyLiked,
    baseCounts: baseCounts,
  );
  if (!started) return;

  unawaited(
    WallInteractionService.instance
        .toggleLike(target)
        .then((_) => Future<void>.delayed(const Duration(milliseconds: 350)))
        .then((_) => _wallOptimism.completeReaction(target))
        .catchError((Object error) {
          _wallOptimism.completeReaction(target);
          if (!context.mounted) return;
          _showWallError(context, error);
        }),
  );
}

void _openComments(
  BuildContext context,
  _FeedItem item,
  WallInteractionTarget target,
) {
  final eco = context.eco;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: eco.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _CommentsSheet(item: item, target: target),
  );
}

void _openReactors(
  BuildContext context,
  _FeedItem item,
  WallInteractionTarget target,
) {
  final eco = context.eco;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: eco.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _ReactorsSheet(item: item, target: target),
  );
}

void _showWallError(BuildContext context, Object error) {
  final eco = context.eco;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('No se pudo completar la accion: $error'),
      backgroundColor: eco.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _WallOptimism extends ChangeNotifier {
  final _reactions = <String, _OptimisticReaction>{};
  final _comments = <String, List<WallComment>>{};

  _OptimisticReaction? like(WallInteractionTarget target) {
    return _reactions[_targetKey(target)];
  }

  bool startLike(
    WallInteractionTarget target, {
    required bool currentlyLiked,
    required Map<String, int> baseCounts,
  }) {
    final key = _targetKey(target);
    if (_reactions.containsKey(key)) return false;

    final nextCounts = Map<String, int>.from(baseCounts);
    if (currentlyLiked) {
      _removeOneLikeCount(nextCounts);
    } else {
      nextCounts['like'] = (nextCounts['like'] ?? 0) + 1;
    }

    _reactions[key] = _OptimisticReaction(
      liked: !currentlyLiked,
      counts: nextCounts,
    );
    notifyListeners();
    return true;
  }

  void completeReaction(WallInteractionTarget target) {
    if (_reactions.remove(_targetKey(target)) != null) {
      notifyListeners();
    }
  }

  int commentCount(_FeedItem item, WallInteractionTarget target) {
    return item.comments + (_comments[_targetKey(target)]?.length ?? 0);
  }

  bool hasPendingComments(WallInteractionTarget target) {
    return _comments[_targetKey(target)]?.isNotEmpty ?? false;
  }

  List<WallComment> commentsWithPending(
    WallInteractionTarget target,
    List<WallComment> serverComments,
  ) {
    final pending = _comments[_targetKey(target)];
    if (pending == null || pending.isEmpty) return serverComments;

    final serverIds = serverComments.map((comment) => comment.id).toSet();
    return [
      ...serverComments,
      for (final comment in pending)
        if (!serverIds.contains(comment.id)) comment,
    ];
  }

  void addPendingComment(WallInteractionTarget target, WallComment comment) {
    final key = _targetKey(target);
    final comments = _comments.putIfAbsent(key, () => <WallComment>[]);
    comments.add(comment);
    notifyListeners();
  }

  void removePendingComment(WallInteractionTarget target, String commentId) {
    final key = _targetKey(target);
    final comments = _comments[key];
    if (comments == null) return;

    comments.removeWhere((comment) => comment.id == commentId);
    if (comments.isEmpty) _comments.remove(key);
    notifyListeners();
  }

  void removePendingComments(
    WallInteractionTarget target,
    Set<String> serverIds,
  ) {
    if (serverIds.isEmpty) return;

    final key = _targetKey(target);
    final comments = _comments[key];
    if (comments == null) return;

    final before = comments.length;
    comments.removeWhere((comment) => serverIds.contains(comment.id));
    if (comments.isEmpty) _comments.remove(key);
    if (comments.length != before) notifyListeners();
  }
}

class _OptimisticReaction {
  const _OptimisticReaction({required this.liked, required this.counts});

  final bool liked;
  final Map<String, int> counts;
}

/// Descuenta un "me gusta" de un mapa de contadores para la vista optimista.
/// Prefiere el contador canonico 'like' y, si no existe, descuenta del primer
/// contador legado con valor positivo para que la suma total baje en 1.
void _removeOneLikeCount(Map<String, int> counts) {
  var key = (counts['like'] ?? 0) > 0 ? 'like' : null;
  key ??= counts.entries
      .firstWhere(
        (entry) => entry.value > 0,
        orElse: () => const MapEntry('', 0),
      )
      .key;
  if (key.isEmpty) return;
  final next = (counts[key] ?? 0) - 1;
  if (next <= 0) {
    counts.remove(key);
  } else {
    counts[key] = next;
  }
}

String _targetKey(WallInteractionTarget target) {
  return '${target.collection}/${target.id}';
}

class _WallEvent {
  const _WallEvent({
    required this.id,
    required this.title,
    required this.type,
    this.body,
    this.locationLabel,
    this.date,
    this.startAt,
    this.endAt,
    this.ownerId,
    this.xpReward,
    this.participantCount,
    this.capacity,
    this.status,
    required this.visibleOnWall,
  });

  final String id;
  final String title;
  final String type;
  final String? body;
  final String? locationLabel;
  final DateTime? date;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? ownerId;
  final int? xpReward;
  final int? participantCount;
  final int? capacity;
  final String? status;
  final bool visibleOnWall;

  String get dateLabel => date == null ? 'Sin fecha' : _shortDate(date!);

  ChipTone get chipTone {
    return switch (type.toLowerCase()) {
      'workshop' || 'taller' => ChipTone.tertiary,
      'cleanup' || 'limpieza' => ChipTone.primary,
      _ => ChipTone.emerald,
    };
  }

  factory _WallEvent.fromMap(String id, Map<String, dynamic> data) {
    final visibility = (_stringValue(data['visibility']) ?? '').toLowerCase();
    return _WallEvent(
      id: id,
      title:
          _firstNonEmpty([
            _stringValue(data['title']),
            _stringValue(data['name']),
          ]) ??
          'Evento sin título',
      type: _stringValue(data['type']) ?? 'event',
      body: _firstNonEmpty([
        _stringValue(data['objectives']),
        _stringValue(data['description']),
        _stringValue(data['body']),
      ]),
      locationLabel: _firstNonEmpty([
        _stringValue(data['locationLabel']),
        _stringValue(data['meetingPoint']),
        _stringValue(data['placeName']),
      ]),
      date: _toDate(data['startAt']) ?? _toDate(data['date']),
      startAt: _toDate(data['startAt']) ?? _toDate(data['date']),
      endAt: _toDate(data['endAt']),
      ownerId: _firstNonEmpty([
        _stringValue(data['authorId']),
        _stringValue(data['createdBy']),
      ]),
      xpReward: _toInt(data['xpReward']),
      participantCount: _toInt(data['participantCount']),
      capacity: _toInt(data['capacity']),
      status: _stringValue(data['status']),
      visibleOnWall:
          data['isPublic'] != false &&
          data['public'] != false &&
          visibility != 'private',
    );
  }
}

enum _PostMediaType { image, video }

class _FeedItem {
  const _FeedItem({
    required this.id,
    required this.sourceKey,
    required this.authorName,
    required this.body,
    required this.chipTone,
    required this.reactionCounts,
    required this.comments,
    this.authorId,
    this.chipLabel,
    this.authorPhotoUrl,
    this.rankLabel,
    this.mediaUrl,
    this.mediaType,
    this.posterUrl,
    this.photoLabel,
    this.placeLabel,
    this.locationPoint,
    this.createdAt,
    this.routePoints,
  });

  final String id;
  final String sourceKey;
  final String? authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String body;
  final String? chipLabel;
  final ChipTone chipTone;
  final String? rankLabel;
  final String? mediaUrl;
  final _PostMediaType? mediaType;
  final String? posterUrl;
  final String? photoLabel;
  final String? placeLabel;
  final LatLng? locationPoint;
  final DateTime? createdAt;
  final Map<String, int> reactionCounts;
  final int comments;

  /// Puntos del recorrido cuando la publicación es de tipo `route`.
  final List<LatLng>? routePoints;

  bool get isRoute => routePoints != null && routePoints!.isNotEmpty;

  bool get hasMapLocation => isRoute || locationPoint != null;

  int get reactions => _sumMapCounts(reactionCounts);

  int get popularity => reactions + comments;

  String? get fieldRecordId {
    const prefix = 'fieldRecords/';
    if (!sourceKey.startsWith(prefix)) return null;
    return sourceKey.substring(prefix.length);
  }

  String get meta {
    final parts = [
      if (createdAt != null) _relativeTime(createdAt!),
      if (placeLabel != null) placeLabel!,
    ];
    return parts.isEmpty ? 'Sin fecha' : parts.join(' · ');
  }

  factory _FeedItem.fromPublicFeed(String id, Map<String, dynamic> data) {
    final author = data['authorSnapshot'] is Map
        ? data['authorSnapshot'] as Map
        : null;
    final counts = data['reactionCounts'] is Map
        ? data['reactionCounts'] as Map
        : null;
    final category = _stringValue(data['category']);
    final species = _stringValue(data['speciesName']);
    final routePoints = _routePointsFromData(data);
    final mediaType = _mediaTypeFromData(data);
    final mediaUrl = mediaType == _PostMediaType.video
        ? _stringValue(data['videoUrl'])
        : _firstNonEmpty([
            _stringValue(data['photoUrl']),
            _stringValue(data['photoThumbUrl']),
          ]);

    return _FeedItem(
      id: id,
      sourceKey: _stringValue(data['sourceRecordId']) ?? 'publicFeed/$id',
      authorId: _stringValue(data['authorId']),
      authorName:
          _firstNonEmpty([
            _stringValue(author?['name']),
            _stringValue(data['authorName']),
          ]) ??
          'Usuario sin nombre',
      authorPhotoUrl: _firstNonEmpty([
        _stringValue(author?['photoUrl']),
        _stringValue(data['authorPhotoUrl']),
      ]),
      body:
          _firstNonEmpty([
            _stringValue(data['bodyPreview']),
            _stringValue(data['notes']),
            species,
          ]) ??
          'Publicación sin descripción',
      chipLabel: _categoryLabel(category),
      chipTone: _chipForCategory(category),
      rankLabel: _firstNonEmpty([
        _stringValue(data['rankLabel']),
        _stringValue(author?['userType']),
        _stringValue(author?['role']),
      ]),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      posterUrl: _firstNonEmpty([
        _stringValue(data['videoThumbUrl']),
        _stringValue(data['photoThumbUrl']),
      ]),
      photoLabel: _firstNonEmpty([_stringValue(data['photoLabel']), species]),
      placeLabel: _firstNonEmpty([
        _stringValue(data['locationLabel']),
        _stringValue(data['placeLabel']),
        _stringValue(data['placeName']),
      ]),
      locationPoint: _locationPointFromData(data),
      createdAt: _toDate(data['createdAt']),
      reactionCounts: _normalizedReactionCounts(counts),
      comments: _toInt(data['commentCount']) ?? 0,
      routePoints: routePoints,
    );
  }

  factory _FeedItem.fromFieldRecord(String id, Map<String, dynamic> data) {
    final author = data['authorSnapshot'] is Map
        ? data['authorSnapshot'] as Map
        : null;
    final reactions = data['reactionCounts'] is Map
        ? data['reactionCounts'] as Map
        : null;
    final evidence = data['evidence'] is List ? data['evidence'] as List : null;
    final firstEvidence = evidence != null && evidence.isNotEmpty
        ? evidence.first
        : null;
    final evidenceMap = firstEvidence is Map ? firstEvidence : null;
    final imageEvidenceMap = evidence?.whereType<Map>().firstWhere(
      (item) => _stringValue(item['type']) == 'image',
      orElse: () => const {},
    );
    final selectedImageEvidence =
        imageEvidenceMap == null || imageEvidenceMap.isEmpty
        ? null
        : imageEvidenceMap;
    final videoEvidenceMap = evidence?.whereType<Map>().firstWhere(
      (item) => _stringValue(item['type']) == 'video',
      orElse: () => const {},
    );
    final selectedVideoEvidence =
        videoEvidenceMap == null || videoEvidenceMap.isEmpty
        ? null
        : videoEvidenceMap;
    final category = _stringValue(data['category']);
    final species = _stringValue(data['speciesName']);

    return _FeedItem(
      id: id,
      sourceKey: 'fieldRecords/$id',
      authorId: _firstNonEmpty([
        _stringValue(data['authorId']),
        _stringValue(data['createdBy']),
      ]),
      authorName:
          _firstNonEmpty([
            _stringValue(author?['name']),
            _stringValue(data['authorName']),
          ]) ??
          'Usuario sin nombre',
      authorPhotoUrl: _firstNonEmpty([
        _stringValue(author?['photoUrl']),
        _stringValue(data['authorPhotoUrl']),
      ]),
      body:
          _firstNonEmpty([
            _stringValue(data['notes']),
            species,
            _categoryLabel(category),
          ]) ??
          'Registro sin descripción',
      chipLabel: _categoryLabel(category),
      chipTone: _chipForCategory(category),
      rankLabel: _firstNonEmpty([
        _stringValue(author?['userType']),
        _stringValue(author?['role']),
      ]),
      mediaUrl: _firstNonEmpty([
        if (selectedImageEvidence != null)
          _stringValue(selectedImageEvidence['displayUrl']),
        if (selectedImageEvidence != null)
          _stringValue(selectedImageEvidence['downloadUrl']),
        if (selectedImageEvidence != null) _stringValue(data['photoUrl']),
        if (selectedImageEvidence != null)
          _stringValue(selectedImageEvidence['thumbUrl']),
        if (selectedImageEvidence != null) _stringValue(data['photoThumbUrl']),
        if (selectedImageEvidence == null && selectedVideoEvidence != null)
          _stringValue(selectedVideoEvidence['videoUrl']),
        if (selectedImageEvidence == null && selectedVideoEvidence != null)
          _stringValue(selectedVideoEvidence['downloadUrl']),
        _stringValue(data['videoUrl']),
        _stringValue(data['photoUrl']),
      ]),
      mediaType: selectedImageEvidence != null
          ? _PostMediaType.image
          : selectedVideoEvidence != null
          ? _PostMediaType.video
          : _mediaTypeFromData(data),
      posterUrl: _firstNonEmpty([
        if (selectedVideoEvidence != null)
          _stringValue(selectedVideoEvidence['thumbUrl']),
        _stringValue(data['videoThumbUrl']),
        _stringValue(data['photoThumbUrl']),
      ]),
      photoLabel: evidenceMap == null
          ? null
          : _firstNonEmpty([
              _stringValue(data['photoLabel']),
              _stringValue(evidenceMap['type']) == 'video'
                  ? 'Video cargado'
                  : null,
              species,
              _categoryLabel(category),
            ]),
      placeLabel: _firstNonEmpty([
        _stringValue(data['locationLabel']),
        _stringValue(data['placeLabel']),
        _stringValue(data['placeName']),
        _stringValue(data['zoneId']),
      ]),
      locationPoint: _locationPointFromData(data),
      createdAt: _toDate(data['createdAt']) ?? _toDate(data['observedAt']),
      reactionCounts: _normalizedReactionCounts(reactions),
      comments: _toInt(data['commentCount']) ?? 0,
    );
  }
}

bool _recordBelongsOnWall(Map<String, dynamic> data) {
  if (data['publishToWall'] == true) return true;
  final visibility = (_stringValue(data['visibility']) ?? '').toLowerCase();
  return visibility == 'public' || visibility == 'team';
}

bool _isClosedStatus(String? status) {
  final value = (status ?? '').toLowerCase();
  return value == 'completed' ||
      value == 'cancelled' ||
      value == 'canceled' ||
      value == 'finalizado' ||
      value == 'cancelado';
}

String _participantsLabel(_WallEvent event) {
  final count = event.participantCount;
  final capacity = event.capacity;
  if (count != null && capacity != null) {
    return '$count/$capacity participantes';
  }
  if (count != null) return '$count participantes';
  return 'Capacidad $capacity';
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int? _toInt(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

int _sumMapCounts(Map? map) {
  if (map == null) return 0;
  return map.values.fold<int>(
    0,
    (total, value) => total + (_toInt(value) ?? 0),
  );
}

Map<String, int> _normalizedReactionCounts(Map? map) {
  if (map == null) return const <String, int>{};
  final counts = <String, int>{};
  for (final entry in map.entries) {
    final value = _toInt(entry.value) ?? 0;
    if (value <= 0) continue;
    final type = _normalizeReactionType(entry.key.toString());
    counts[type] = (counts[type] ?? 0) + value;
  }
  return counts;
}

String _normalizeReactionType(String? value) {
  return switch ((value ?? '').trim().toLowerCase()) {
    'visto' => 'visto',
    'confirmo' || 'confirmó' || 'confirm' => 'confirmo',
    'proteger' || 'protect' => 'proteger',
    'foto' || 'photo' || 'like' || 'heart' || 'love' => 'foto',
    _ => 'foto',
  };
}

LatLng? _locationPointFromData(Map<String, dynamic> data) {
  final location = data['location'];
  if (location is GeoPoint) {
    return _safeLatLng(location.latitude, location.longitude);
  }

  final latitude = _toDouble(
    data['latitude'] ?? data['lat'] ?? data['locationLatitude'],
  );
  final longitude = _toDouble(
    data['longitude'] ??
        data['lng'] ??
        data['lon'] ??
        data['locationLongitude'],
  );
  return _safeLatLng(latitude, longitude);
}

/// Crea un LatLng solo si las coordenadas son finitas y están en rango; si no,
/// devuelve null para no propagar valores corruptos (NaN/Infinity) al mapa,
/// que de otro modo lanza "LatLng is not finite".
LatLng? _safeLatLng(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return LatLng(lat, lng);
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
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

String? _categoryLabel(String? value) {
  return switch ((value ?? '').toLowerCase()) {
    'fauna' => 'Fauna',
    'flora' => 'Flora',
    'incident' || 'incidente' => 'Incidente',
    'trash' || 'basura' => 'Basura',
    'route' || 'recorrido' => 'Recorrido',
    _ => null,
  };
}

List<LatLng>? _routePointsFromData(Map<String, dynamic> data) {
  if ((_stringValue(data['postType']) ?? '').toLowerCase() != 'route') {
    return null;
  }
  final raw = data['routePoints'];
  if (raw is! List) return null;
  final points = <LatLng>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final lat = item['lat'];
    final lng = item['lng'];
    if (lat is! num || lng is! num) continue;
    final point = _safeLatLng(lat.toDouble(), lng.toDouble());
    if (point != null) points.add(point);
  }
  return points.isEmpty ? null : points;
}

_PostMediaType? _mediaTypeFromData(Map<String, dynamic> data) {
  final explicit = (_stringValue(data['mediaType']) ?? '').toLowerCase();
  if (explicit == 'video') return _PostMediaType.video;
  if (explicit == 'image') return _PostMediaType.image;
  if (_stringValue(data['videoUrl']) != null) return _PostMediaType.video;
  if (_stringValue(data['photoUrl']) != null ||
      _stringValue(data['photoThumbUrl']) != null) {
    return _PostMediaType.image;
  }
  return null;
}

ChipTone _chipForCategory(String? value) {
  return switch ((value ?? '').toLowerCase()) {
    'fauna' => ChipTone.emerald,
    'flora' => ChipTone.tertiary,
    'incident' || 'incidente' => ChipTone.warning,
    'trash' || 'basura' => ChipTone.primary,
    'route' || 'recorrido' => ChipTone.emerald,
    _ => ChipTone.slate,
  };
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

String _shortDate(DateTime date) {
  const months = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 30) return 'Hace ${diff.inDays} días';
  return _shortDate(date);
}
