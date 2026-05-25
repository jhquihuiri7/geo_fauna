import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/auth_service.dart';
import '../services/wall_media_cache_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';
import 'settings_screen.dart';
import 'integridad_screen.dart';

/// Datos del perfil resueltos a partir de Firestore + Firebase Auth.
class _Profile {
  _Profile(Map<String, dynamic>? data, User? user)
      : name = _firstNonEmpty(
            [data?['name'] as String?, user?.displayName, 'Investigador'])!,
        userType = _firstNonEmpty([data?['userType'] as String?]) ?? '—',
        rangerId = _firstNonEmpty([data?['rangerId'] as String?]) ?? '—',
        specialty = _firstNonEmpty([data?['specialty'] as String?]) ?? '—',
        email =
            _firstNonEmpty([data?['email'] as String?, user?.email]) ?? '—',
        photoUrl = _firstNonEmpty([data?['photoUrl'] as String?, user?.photoURL]),
        parkName = _firstNonEmpty([data?['parkName'] as String?]) ??
            'Parque Nacional\nGalápagos',
        statusLabel =
            (_firstNonEmpty([data?['status'] as String?]) ?? 'Activo')
                .toUpperCase();

  final String name;
  final String userType;
  final String rangerId;
  final String specialty;
  final String email;
  final String? photoUrl;
  final String parkName;
  final String statusLabel;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase();
  }

  /// Contenido del QR de identificación: prioriza el ID de guardaparque y, si
  /// no existe, recurre al correo o al nombre para que siga siendo escaneable.
  String get qrData {
    final id = rangerId != '—'
        ? rangerId
        : (email != '—' ? email : name);
    return 'geofauna:ranger:$id';
  }

  /// Subtítulo del encabezado: "Guía Naturalista · GNPS-2024-001".
  String get roleLine {
    final bits = [
      if (userType != '—') userType,
      if (rangerId != '—') rangerId,
    ];
    return bits.isEmpty ? 'Perfil de campo' : bits.join(' · ');
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}

/// Perfil — agent profile: digital ID, stats, personal wall (screens-main2.jsx).
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final auth = AuthService();
    final user = auth.currentUser;

    return Container(
      color: eco.surface,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user != null ? auth.userDoc(user.uid) : null,
        builder: (context, snap) {
          final p = _Profile(snap.data?.data(), user);
          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              EcoTopBar(
                title: 'Mi Bitácora',
                leading: _avatar(p, 40),
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
                    Text(p.name,
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1,
                            color: eco.onSurface)),
                    const SizedBox(height: 8),
                    Text(p.roleLine,
                        style: TextStyle(
                            fontSize: 14, color: eco.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    _idCard(eco, p),
                    const SizedBox(height: 24),
                    _statsAndWall(eco, user),
                    const SizedBox(height: 24),
                    _actions(context, eco),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Avatar con foto real si existe; si no, iniciales del usuario.
  Widget _avatar(_Profile p, double size) {
    if (p.photoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(p.photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Avatar(
        name: p.name,
        size: size,
        tone: AvatarTone.forest,
        status: AvatarStatus.on);
  }

  Widget _idCard(AppColors eco, _Profile p) {
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
                Text(p.parkName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: Colors.white)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: cell('Tipo', p.userType)),
                    Expanded(child: cell('Especialidad', p.specialty)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: cell('ID', p.rangerId)),
                    Expanded(child: cell('Correo', p.email)),
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
                    children: [
                      const SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: Color(0xFF86EFAC),
                                  shape: BoxShape.circle))),
                      const SizedBox(width: 8),
                      Text(p.statusLabel,
                          style: const TextStyle(
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
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: QrImageView(
              data: p.qrData,
              version: QrVersions.auto,
              gapless: true,
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estadísticas + muro personal. Lee los `fieldRecords` del usuario una sola
  /// vez y los reutiliza para (a) calcular la precisión a partir de las
  /// validaciones y (b) renderizar el muro de avistamientos.
  Widget _statsAndWall(AppColors eco, User? user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('fieldRecords')
              .where('authorId', isEqualTo: user.uid)
              .snapshots()
          : null,
      builder: (context, recSnap) {
        final docs = recSnap.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        // Precisión = confirmaciones / (confirmaciones + disputas) sobre los
        // registros del usuario. Si aún no hay votos, queda en "—".
        var confirmations = 0;
        var disputes = 0;
        for (final d in docs) {
          final vs = d.data()['validationSummary'];
          if (vs is Map) {
            confirmations += _statNum(vs['confirmations']).round();
            disputes += _statNum(vs['disputes']).round();
          }
        }
        final totalVotes = confirmations + disputes;
        final precisionLabel = totalVotes == 0
            ? '—'
            : '${(confirmations / totalVotes * 100).round()}%';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stats(eco, user, precisionLabel),
            const SizedBox(height: 24),
            _wall(eco, docs),
          ],
        );
      },
    );
  }

  Widget _stats(AppColors eco, User? user, String precisionLabel) {
    // Métricas reales agregadas en `userStats` por FieldDataService.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('userStats')
              .doc(user.uid)
              .snapshots()
          : null,
      builder: (context, snap) {
        final s = snap.data?.data() ?? const <String, dynamic>{};
        final sightings = _statNum(s['fieldRecordCount']).round();
        final tracks = _statNum(s['trackCount']).round();
        final km = _statNum(s['trackDistanceMeters']) / 1000;
        final hours = _statNum(s['fieldSeconds']) / 3600;
        // Nivel derivado del XP acumulado (+25 por registro, +50 por recorrido).
        final xp = _statNum(s['xp']).round();
        final level = xp ~/ 100 + 1;
        final cells = [
          [Icons.visibility, 'Avistamientos', '$sightings', false],
          [Icons.route, 'Recorridos', '$tracks', false],
          [Icons.verified, 'Precisión', precisionLabel, false],
          [Icons.timer, 'En Campo', '${hours.toStringAsFixed(hours < 10 ? 1 : 0)}h', false],
          [Icons.map, 'Distancia', '${km.toStringAsFixed(km < 100 ? 1 : 0)}km', false],
          [Icons.workspace_premium, 'Nivel', 'Nv $level', false],
        ];
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: [
            for (final c in cells)
              _StatCell(
                  icon: c[0] as IconData,
                  label: c[1] as String,
                  value: c[2] as String,
                  small: c[3] as bool),
          ],
        );
      },
    );
  }

  static double _statNum(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Devuelve la miniatura (o foto) representativa de un registro, si existe.
  static String? _thumbUrl(Map<String, dynamic> data) {
    for (final key in const ['photoThumbUrl', 'photoUrl', 'videoThumbUrl']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  Widget _wall(
    AppColors eco,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    // Orden por fecha desc en cliente: evita un índice compuesto en Firestore.
    final sorted = [...docs]..sort((a, b) {
      final ta = a.data()['createdAt'];
      final tb = b.data()['createdAt'];
      final va = ta is Timestamp ? ta.toDate() : DateTime(0);
      final vb = tb is Timestamp ? tb.toDate() : DateTime(0);
      return vb.compareTo(va);
    });
    final withMedia = [
      for (final d in sorted)
        if (_thumbUrl(d.data()) != null) d,
    ];
    WallMediaCacheService.instance
        .warm([for (final d in withMedia) _thumbUrl(d.data())]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MI MURO DE AVISTAMIENTO',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: eco.primary)),
        const SizedBox(height: 16),
        if (withMedia.isEmpty)
          _wallEmpty(eco)
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              for (final d in withMedia.take(12))
                _WallThumb(
                  url: _thumbUrl(d.data())!,
                  label: (d.data()['speciesName'] as String?) ??
                      (d.data()['categoryLabel'] as String?) ??
                      'AVISTAMIENTO',
                ),
            ],
          ),
      ],
    );
  }

  /// Estado vacío: aún no hay avistamientos con evidencia registrados.
  Widget _wallEmpty(AppColors eco) {
    return EcoCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.photo_camera_outlined,
                color: eco.primary, size: 26),
          ),
          const SizedBox(height: 12),
          Text('Aún no tienes avistamientos',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: eco.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Registra tu primer hallazgo desde la pestaña "Nuevo".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: eco.onSurfaceVariant),
          ),
        ],
      ),
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
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }
}

/// Miniatura cuadrada del muro personal, servida desde la caché de medios del
/// muro para reutilizar archivos ya descargados en la pestaña comunitaria.
class _WallThumb extends StatelessWidget {
  const _WallThumb({required this.url, this.label});

  final String url;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: StreamBuilder<FileResponse>(
        stream: WallMediaCacheService.instance.fileStream(url),
        builder: (context, snap) {
          final data = snap.data;
          if (data is FileInfo) {
            return Image.file(
              data.file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stack) =>
                  PhotoPlaceholder(label: label ?? '', borderRadius: 16),
            );
          }
          if (snap.hasError) {
            return PhotoPlaceholder(label: label ?? '', borderRadius: 16);
          }
          return Container(
            color: eco.surfaceContainerLow,
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: eco.primary,
                value: data is DownloadProgress ? data.progress : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

