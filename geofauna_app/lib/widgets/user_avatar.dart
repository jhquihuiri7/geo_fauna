import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'eco_widgets.dart';

/// Avatar del usuario autenticado: muestra su foto de perfil real (de Firestore
/// o de la cuenta de Google) y, si no hay foto, sus iniciales. Se actualiza en
/// vivo ante cambios del documento del usuario.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size = 40,
    this.status = AvatarStatus.none,
    this.tone = AvatarTone.forest,
  });

  final double size;
  final AvatarStatus status;
  final AvatarTone tone;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user != null ? auth.userDoc(user.uid) : null,
      builder: (context, snap) {
        final data = snap.data?.data();
        final photoUrl =
            (data?['photoUrl'] as String?) ?? user?.photoURL;
        final name = (data?['name'] as String?) ?? user?.displayName ?? '';

        if (photoUrl != null && photoUrl.isNotEmpty) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.eco.primary.withValues(alpha: 0.25),
                        blurRadius: size * 0.28,
                        offset: Offset(0, size * 0.12),
                      ),
                    ],
                  ),
                ),
                if (status != AvatarStatus.none)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: size * 0.28,
                      height: size * 0.28,
                      decoration: BoxDecoration(
                        color: status == AvatarStatus.on
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.eco.surfaceContainerLowest,
                            width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Sin foto: iniciales (o un emoji por defecto si aún no hay nombre).
        return Avatar(
          name: name.isEmpty ? null : name,
          emoji: name.isEmpty ? '🦫' : null,
          size: size,
          tone: tone,
          status: status,
        );
      },
    );
  }
}
