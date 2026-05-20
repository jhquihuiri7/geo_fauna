import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_widgets.dart';

/// Settings — account configuration; the dark-mode switch drives the global
/// [themeModeNotifier] (screens-extra.jsx).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushField = true;
  bool _pushWall = false;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: eco.surface,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'Configuración de Cuenta',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  EcoCard(
                    radius: 32,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 30),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            const Avatar(
                                size: 96,
                                tone: AvatarTone.forest,
                                emoji: '🦫'),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: eco.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: eco.surfaceContainerLowest,
                                      width: 3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Carlos Jaramillo',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: eco.onSurface)),
                        const SizedBox(height: 4),
                        Text('c.jaramillo@parquegalapagos.gob.ec',
                            style: TextStyle(
                                fontSize: 14, color: eco.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            EcoChip('Guardaparque Senior',
                                tone: ChipTone.tertiary),
                            SizedBox(width: 8),
                            EcoChip('Sector Sur', tone: ChipTone.emerald),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _group(eco, 'Perfil Personal', [
                    EcoListRow(
                        icon: Icons.manage_accounts,
                        title: 'Editar Información',
                        trailing:
                            Icon(Icons.chevron_right, color: eco.outline)),
                    _sep(eco),
                    EcoListRow(
                        icon: Icons.badge,
                        title: 'Identificación Digital',
                        trailing:
                            Icon(Icons.chevron_right, color: eco.outline)),
                  ]),
                  const SizedBox(height: 24),
                  _group(eco, 'Seguridad', [
                    EcoListRow(
                        icon: Icons.lock_reset,
                        title: 'Cambiar Contraseña',
                        iconBg: eco.tertiary.withValues(alpha: 0.12),
                        iconColor: eco.tertiary,
                        trailing:
                            Icon(Icons.chevron_right, color: eco.outline)),
                    _sep(eco),
                    EcoListRow(
                      icon: Icons.security,
                      title: 'Autenticación de dos pasos',
                      iconBg: eco.tertiary.withValues(alpha: 0.12),
                      iconColor: eco.tertiary,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ACTIVO',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: eco.primary)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: eco.outline),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _group(eco, 'Notificaciones', [
                    EcoListRow(
                        icon: Icons.notifications_active,
                        title: 'Alertas de Campo',
                        subtitle: 'Especies críticas y clima',
                        iconBg: eco.tertiary.withValues(alpha: 0.12),
                        iconColor: eco.tertiary,
                        trailing: EcoSwitch(
                            value: _pushField,
                            onChanged: (v) => setState(() => _pushField = v))),
                    _sep(eco),
                    EcoListRow(
                        icon: Icons.forum,
                        title: 'Mensajes del Muro',
                        subtitle: 'Interacciones con equipo',
                        iconBg: eco.tertiary.withValues(alpha: 0.12),
                        iconColor: eco.tertiary,
                        trailing: EcoSwitch(
                            value: _pushWall,
                            onChanged: (v) => setState(() => _pushWall = v))),
                  ]),
                  const SizedBox(height: 24),
                  _group(eco, 'Preferencias', [
                    EcoListRow(
                        icon: Icons.dark_mode,
                        title: 'Modo Oscuro',
                        iconBg: eco.surfaceContainer,
                        iconColor: eco.onSurface,
                        trailing: EcoSwitch(
                          value: isDark,
                          onChanged: (v) => themeModeNotifier.value =
                              v ? ThemeMode.dark : ThemeMode.light,
                        )),
                    _sep(eco),
                    EcoListRow(
                      icon: Icons.language,
                      title: 'Idioma',
                      iconBg: eco.surfaceContainer,
                      iconColor: eco.onSurface,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Español',
                              style: TextStyle(
                                  fontSize: 14, color: eco.onSurfaceVariant)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: eco.outline),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      await AuthService().signOut();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
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
                  const SizedBox(height: 24),
                  Center(
                    child: Text('ECOGUÍA GALÁPAGOS · V2.4.0',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: eco.outline)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(AppColors eco, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: eco.onSurfaceVariant)),
        ),
        EcoCard(
          radius: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _sep(AppColors eco) => Padding(
        padding: const EdgeInsets.only(left: 60),
        child: Container(height: 1, color: eco.surfaceContainer),
      );
}
