import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/wall_interaction_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/user_avatar.dart';

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

            return Column(
              children: [
                for (final entry in feed.take(20).toList().asMap().entries)
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
    );
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
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
                        Text(
                          item.meta,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: eco.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      EcoChip(item.chipLabel, tone: item.chipTone),
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
                  if (item.photoUrl != null || item.photoLabel != null) ...[
                    const SizedBox(height: 16),
                    _media(item),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _InteractionBar(item: item, target: target),
            ),
            if (highlighted)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: eco.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: eco.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Publicacion abierta desde la notificacion',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: eco.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _authorAvatar(_FeedItem item) {
    if (item.authorPhotoUrl != null) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(item.authorPhotoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Avatar(name: item.authorName, tone: AvatarTone.forest, size: 42);
  }

  Widget _media(_FeedItem item) {
    if (item.photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            item.photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return PhotoPlaceholder(
                label: item.photoLabel ?? 'IMAGEN NO DISPONIBLE',
                borderRadius: 28,
              );
            },
          ),
        ),
      );
    }
    return PhotoPlaceholder(label: item.photoLabel!, borderRadius: 28);
  }
}

class _InteractionBar extends StatelessWidget {
  const _InteractionBar({required this.item, required this.target});

  final _FeedItem item;
  final WallInteractionTarget target;

  @override
  Widget build(BuildContext context) {
    final service = WallInteractionService.instance;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StreamBuilder<bool>(
          stream: service.userConfirmationStream(target),
          builder: (context, snap) {
            final active = snap.data ?? false;
            return _ActionPill(
              icon: Icons.verified,
              label: '${item.confirmations} confirmaciones',
              active: active,
              onTap: () => _runWallAction(
                context,
                () => service.toggleConfirmation(target),
              ),
            );
          },
        ),
        StreamBuilder<bool>(
          stream: service.userReactionStream(target),
          builder: (context, snap) {
            final active = snap.data ?? false;
            return _ActionPill(
              icon: Icons.favorite,
              label: '${item.reactions} reacciones',
              active: active,
              onTap: () =>
                  _runWallAction(context, () => service.toggleReaction(target)),
            );
          },
        ),
        _ActionPill(
          icon: Icons.add_comment,
          label: '${item.comments} comentarios',
          onTap: () => _openComments(context, item, target),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final bg = active
        ? eco.primary.withValues(alpha: 0.10)
        : eco.surfaceContainerLow;
    final fg = active ? eco.primary : eco.onSurfaceVariant;
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
                  ? Border.all(color: eco.primary.withValues(alpha: 0.22))
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

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.item, required this.target});

  final _FeedItem item;
  final WallInteractionTarget target;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

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
                  EcoChip('${widget.item.comments}', tone: ChipTone.slate),
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
                    if (comments.isEmpty) {
                      return _sheetState(
                        eco,
                        icon: Icons.chat_bubble_outline,
                        title: 'Sin comentarios',
                        message: 'Se el primero en comentar esta publicacion.',
                      );
                    }
                    return ListView.separated(
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _CommentRow(comment: comments[index]),
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
                        enabled: !_sending,
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
                      icon: _sending ? Icons.hourglass_top : Icons.send,
                      onTap: _sending ? null : _send,
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await WallInteractionService.instance.addComment(widget.target, text);
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      _showWallError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
    return Row(
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

Future<void> _runWallAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    _showWallError(context, error);
  }
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

class _WallEvent {
  const _WallEvent({
    required this.id,
    required this.title,
    required this.type,
    this.body,
    this.locationLabel,
    this.date,
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

class _FeedItem {
  const _FeedItem({
    required this.id,
    required this.sourceKey,
    required this.authorName,
    required this.body,
    required this.chipLabel,
    required this.chipTone,
    required this.confirmations,
    required this.reactions,
    required this.comments,
    this.authorPhotoUrl,
    this.rankLabel,
    this.photoUrl,
    this.photoLabel,
    this.placeLabel,
    this.createdAt,
  });

  final String id;
  final String sourceKey;
  final String authorName;
  final String? authorPhotoUrl;
  final String body;
  final String chipLabel;
  final ChipTone chipTone;
  final String? rankLabel;
  final String? photoUrl;
  final String? photoLabel;
  final String? placeLabel;
  final DateTime? createdAt;
  final int confirmations;
  final int reactions;
  final int comments;

  int get popularity => confirmations + reactions + comments;

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
    final validation = data['validationSummary'] is Map
        ? data['validationSummary'] as Map
        : null;
    final category = _stringValue(data['category']);
    final species = _stringValue(data['speciesName']);

    return _FeedItem(
      id: id,
      sourceKey: _stringValue(data['sourceRecordId']) ?? 'publicFeed/$id',
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
      chipLabel:
          _firstNonEmpty([
            _stringValue(data['integrityLabel']),
            _categoryLabel(category),
          ]) ??
          'Registro',
      chipTone: _chipForCategory(category),
      rankLabel: _firstNonEmpty([
        _stringValue(data['rankLabel']),
        _stringValue(author?['userType']),
        _stringValue(author?['role']),
      ]),
      photoUrl: _firstNonEmpty([
        _stringValue(data['photoThumbUrl']),
        _stringValue(data['photoUrl']),
      ]),
      photoLabel: _firstNonEmpty([_stringValue(data['photoLabel']), species]),
      placeLabel: _firstNonEmpty([
        _stringValue(data['placeLabel']),
        _stringValue(data['placeName']),
      ]),
      createdAt: _toDate(data['createdAt']),
      confirmations: _toInt(validation?['confirmations']) ?? 0,
      reactions: _sumMapCounts(counts),
      comments: _toInt(data['commentCount']) ?? 0,
    );
  }

  factory _FeedItem.fromFieldRecord(String id, Map<String, dynamic> data) {
    final author = data['authorSnapshot'] is Map
        ? data['authorSnapshot'] as Map
        : null;
    final validation = data['validationSummary'] is Map
        ? data['validationSummary'] as Map
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
    final category = _stringValue(data['category']);
    final species = _stringValue(data['speciesName']);

    return _FeedItem(
      id: id,
      sourceKey: 'fieldRecords/$id',
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
      chipLabel:
          _firstNonEmpty([
            _stringValue(data['integrityLabel']),
            _statusLabel(_stringValue(data['status'])),
            _categoryLabel(category),
          ]) ??
          'Registro',
      chipTone: _chipForCategory(category),
      rankLabel: _firstNonEmpty([
        _stringValue(author?['userType']),
        _stringValue(author?['role']),
      ]),
      photoUrl: _firstNonEmpty([
        if (selectedImageEvidence != null)
          _stringValue(selectedImageEvidence['thumbUrl']),
        if (selectedImageEvidence != null)
          _stringValue(selectedImageEvidence['downloadUrl']),
        if (evidenceMap == null || selectedImageEvidence != null)
          _stringValue(data['photoUrl']),
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
        _stringValue(data['placeLabel']),
        _stringValue(data['placeName']),
        _stringValue(data['zoneId']),
      ]),
      createdAt: _toDate(data['createdAt']) ?? _toDate(data['observedAt']),
      confirmations: _toInt(validation?['confirmations']) ?? 0,
      reactions: _sumMapCounts(reactions),
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
    _ => null,
  };
}

String? _statusLabel(String? value) {
  return switch ((value ?? '').toLowerCase()) {
    'verified' || 'verificado' => 'Verificado',
    'needs_review' || 'revision' => 'Revisión',
    'submitted' || 'enviado' => 'Enviado',
    'rejected' || 'rechazado' => 'Rechazado',
    _ => null,
  };
}

ChipTone _chipForCategory(String? value) {
  return switch ((value ?? '').toLowerCase()) {
    'fauna' => ChipTone.emerald,
    'flora' => ChipTone.tertiary,
    'incident' || 'incidente' => ChipTone.warning,
    'trash' || 'basura' => ChipTone.primary,
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
