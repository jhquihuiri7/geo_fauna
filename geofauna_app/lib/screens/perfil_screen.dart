import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import '../widgets/painters.dart';
import 'settings_screen.dart';
import 'integridad_screen.dart';

/// Perfil — agent profile: digital ID, stats, personal wall (screens-main2.jsx).
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      color: eco.surface,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          EcoTopBar(
            title: 'Mi Bitácora',
            leading: const Avatar(
                size: 40,
                tone: AvatarTone.forest,
                emoji: '🦫',
                status: AvatarStatus.on),
            trailing: [Icon(Icons.cloud_done, color: eco.primary)],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PERFIL DEL AGENTE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: eco.primary)),
                const SizedBox(height: 4),
                Text('Carlos Jaramillo',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1,
                        color: eco.onSurface)),
                const SizedBox(height: 8),
                Text('Guía Nacional GN-2024',
                    style:
                        TextStyle(fontSize: 14, color: eco.onSurfaceVariant)),
                const SizedBox(height: 24),
                _idCard(eco),
                const SizedBox(height: 24),
                _stats(eco),
                const SizedBox(height: 24),
                _wall(eco),
                const SizedBox(height: 24),
                _actions(context, eco),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idCard(AppColors eco) {
    Widget cell(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white70)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        );
    return GradientPanel(
      radius: 32,
      dots: true,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('IDENTIFICACIÓN DIGITAL',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white70)),
                const SizedBox(height: 4),
                const Text('Parque Nacional\nGalápagos',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: Colors.white)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: cell('Sector', 'Isla Santa Cruz')),
                    Expanded(child: cell('Rango', 'Especialista III')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: cell('Asignado', 'Charles Darwin')),
                    Expanded(child: cell('ID', '8829-XJ-2024')),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: Color(0xFF86EFAC),
                                  shape: BoxShape.circle))),
                      SizedBox(width: 8),
                      Text('ACTIVO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(painter: QrArtPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats(AppColors eco) {
    final cells = const [
      [Icons.visibility, 'Avistamientos', '1,204', false],
      [Icons.eco, 'Especies', '87', false],
      [Icons.verified, 'Precisión', '98%', false],
      [Icons.timer, 'En Campo', '42h', false],
      [Icons.map, 'Recorrido', '482km', false],
      [Icons.workspace_premium, 'Destacado', 'P. Carola', true],
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: [
        for (final c in cells)
          _StatCell(
              icon: c[0] as IconData,
              label: c[1] as String,
              value: c[2] as String,
              small: c[3] as bool),
      ],
    );
  }

  Widget _wall(AppColors eco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MI MURO DE AVISTAMIENTO',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: eco.primary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Column(
              children: [
                Text('Recientes',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: eco.primary)),
                const SizedBox(height: 4),
                Container(width: 18, height: 2, color: eco.primary),
              ],
            ),
            const SizedBox(width: 20),
            Text('Populares',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: eco.outline)),
          ],
        ),
        const SizedBox(height: 16),
        const _MiniSighting(
            emoji: '🐢',
            name: 'Tortuga Gigante',
            place: 'Reserva El Chato',
            likes: '24',
            comments: '8',
            tone: 3),
        const SizedBox(height: 12),
        const _MiniSighting(
            emoji: '🐦',
            name: 'Piquero Patas Azules',
            place: 'Playa de los Perros',
            likes: '18',
            comments: '5',
            tone: 2),
      ],
    );
  }

  Widget _actions(BuildContext context, AppColors eco) {
    Widget tile(IconData icon, String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(icon, color: eco.onSurface, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface)),
              ),
              Icon(Icons.chevron_right, color: eco.outline),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        tile(Icons.settings, 'Configuración de Cuenta', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }),
        const SizedBox(height: 12),
        tile(Icons.shield, 'Protocolo de Integridad de Datos', () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const IntegridadScreen()));
        }),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => AuthService().signOut(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: eco.errorContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: eco.error),
                const SizedBox(width: 8),
                Text('CERRAR SESIÓN',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: eco.error)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return EcoCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: eco.primary),
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: small ? 14 : 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: eco.onSurface)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: eco.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MiniSighting extends StatelessWidget {
  const _MiniSighting({
    required this.emoji,
    required this.name,
    required this.place,
    required this.likes,
    required this.comments,
    required this.tone,
  });

  final String emoji;
  final String name;
  final String place;
  final String likes;
  final String comments;
  final int tone;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return EcoCard(
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: PhotoPlaceholder(
                tone: tone, label: '', emoji: emoji, aspectRatio: 1, borderRadius: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurface)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: eco.primary),
                    const SizedBox(width: 4),
                    Text(place,
                        style: TextStyle(
                            fontSize: 11, color: eco.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 14, color: eco.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(likes,
                        style: TextStyle(
                            fontSize: 12, color: eco.onSurfaceVariant)),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble,
                        size: 14, color: eco.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(comments,
                        style: TextStyle(
                            fontSize: 12, color: eco.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
