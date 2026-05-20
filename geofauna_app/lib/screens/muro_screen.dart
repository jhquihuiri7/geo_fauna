import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';

/// Muro — community wall with upcoming events + sighting feed (screens-main.jsx).
class MuroScreen extends StatefulWidget {
  const MuroScreen({super.key});

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
            leading: const Avatar(
                name: 'Carlos J',
                tone: AvatarTone.forest,
                size: 42,
                emoji: '🦫',
                status: AvatarStatus.on),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.local_fire_department,
                    size: 12, color: Color(0xFFF97316)),
                SizedBox(width: 4),
                Text('12 Días · 2.4k XP'),
              ],
            ),
            trailing: [
              CircleIconButton(icon: Icons.notifications, onTap: () {}),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Kicker('Eventos Próximos',
                    action: Text('Ver todos',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: eco.primary))),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _EventCard(
                    date: '24 OCT',
                    xp: '+25 XP',
                    tone: ChipTone.tertiary,
                    title: 'Workshop: Corales',
                    body:
                        'Técnicas de monitoreo avanzado en Bahía Academia. ¿Te sumas?'),
                SizedBox(width: 16),
                _EventCard(
                    date: '28 OCT',
                    xp: '+40 XP',
                    tone: ChipTone.primary,
                    title: 'Limpieza de Playa',
                    body:
                        'Juntos por Tortuga Bay. Remoción de microplásticos con el equipo.'),
                SizedBox(width: 16),
                _EventCard(
                    date: '02 NOV',
                    xp: '+15 XP',
                    tone: ChipTone.primary,
                    title: 'Censo de Iguanas',
                    body:
                        'Conteo en Plaza Sur. Reúne tu equipo a primera hora.'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MURO DE AVISTAMIENTOS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: eco.onSurfaceVariant,
                      ),
                    ),
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
                                        color: eco.primary),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SightingCard(
                  author: 'Martín Solís',
                  meta: 'Hace 2 horas · Isla Española',
                  avatarTone: AvatarTone.blue,
                  avatarEmoji: '🧑‍🔬',
                  chipTone: ChipTone.emerald,
                  chipLabel: 'Estable',
                  rank: 'RANGO: SENIOR',
                  body:
                      '¡Miren este hallazgo! Un Albatros juvenil fuera de su zona típica. Su plumaje está impecable y parece estar en excelente estado de salud. ¿Alguien más lo ha visto hoy?',
                  photoEmoji: '🐦',
                  photoLabel: 'ALBATROS — ESPAÑOLA',
                  photoTone: 2,
                  commentAuthor: 'Dra. Elena Ruiz',
                  commentEmoji: '👩‍🔬',
                  commentText:
                      '¡Excelente registro! ¿Pudiste captar el sonido de sus llamados? Sería ideal para nuestra base de datos comparativa.',
                ),
                const SizedBox(height: 24),
                const _SightingCard(
                  author: 'Sofía Mendoza',
                  meta: 'Hace 5 horas · Bahía Tortuga',
                  avatarTone: AvatarTone.coral,
                  avatarEmoji: '👩‍🌾',
                  chipTone: ChipTone.warning,
                  chipLabel: 'Atención',
                  rank: 'RANGO: AVANZADO',
                  body:
                      'Grupo de iguanas marinas en zona inusual del intermareal. Conteo aproximado: 14 individuos adultos. Sin signos de estrés térmico.',
                  photoEmoji: '🦎',
                  photoLabel: 'IGUANA MARINA',
                  photoTone: 3,
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
  const _EventCard({
    required this.date,
    required this.xp,
    required this.tone,
    required this.title,
    required this.body,
  });

  final String date;
  final String xp;
  final ChipTone tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return SizedBox(
      width: 268,
      child: EcoCard(
        soft: true,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EcoChip('$date · $xp', tone: tone),
            const SizedBox(height: 16),
            Text(
              title,
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
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, height: 1.4, color: eco.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: eco.primary,
                  foregroundColor: eco.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Me anoto',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SightingCard extends StatelessWidget {
  const _SightingCard({
    required this.author,
    required this.meta,
    required this.avatarTone,
    required this.avatarEmoji,
    required this.chipTone,
    required this.chipLabel,
    required this.rank,
    required this.body,
    required this.photoEmoji,
    required this.photoLabel,
    required this.photoTone,
    this.commentAuthor,
    this.commentEmoji,
    this.commentText,
  });

  final String author;
  final String meta;
  final AvatarTone avatarTone;
  final String avatarEmoji;
  final ChipTone chipTone;
  final String chipLabel;
  final String rank;
  final String body;
  final String photoEmoji;
  final String photoLabel;
  final int photoTone;
  final String? commentAuthor;
  final String? commentEmoji;
  final String? commentText;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      decoration: BoxDecoration(
        color: eco.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(36),
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
                  Avatar(
                      name: author,
                      tone: avatarTone,
                      emoji: avatarEmoji,
                      size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: eco.onSurface)),
                        const SizedBox(height: 4),
                        Text(meta,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: eco.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      EcoChip(chipLabel, tone: chipTone),
                      const SizedBox(height: 6),
                      Text(rank,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: eco.outline)),
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
                  Text(body,
                      style: TextStyle(
                          fontSize: 15, height: 1.4, color: eco.onSurface)),
                  const SizedBox(height: 16),
                  PhotoPlaceholder(
                    tone: photoTone,
                    label: photoLabel,
                    emoji: photoEmoji,
                    borderRadius: 28,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ActionBtn(
                      icon: Icons.verified,
                      label: 'Confirmar (+2 XP)',
                      tone: ChipTone.primary,
                      filled: true),
                  _ActionBtn(
                      icon: Icons.favorite,
                      label: '¡Qué foto!',
                      tone: ChipTone.slate),
                  _ActionBtn(
                      icon: Icons.add_comment,
                      label: '¿Qué opinas?',
                      tone: ChipTone.slate),
                ],
              ),
            ),
            if (commentText != null)
              Container(
                width: double.infinity,
                color: eco.surfaceContainerLow,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Avatar(
                        name: commentAuthor,
                        tone: AvatarTone.slate,
                        emoji: commentEmoji,
                        size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EcoCard(
                            radius: 24,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(commentAuthor!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: eco.onSurface)),
                                const SizedBox(height: 4),
                                Text(commentText!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: eco.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('Responder',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: eco.primary)),
                          ),
                        ],
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
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.tone,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final ChipTone tone;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final isPrimary = tone == ChipTone.primary;
    final bg = isPrimary
        ? eco.primary.withValues(alpha: 0.10)
        : eco.surfaceContainerLow;
    final fg = isPrimary ? eco.primary : eco.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900, color: fg)),
        ],
      ),
    );
  }
}
