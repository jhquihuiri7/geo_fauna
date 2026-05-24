import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_widgets.dart';

class _AccountProfile {
  _AccountProfile(Map<String, dynamic>? data, User? user)
    : name =
          _firstNonEmpty([
            data?['name'] as String?,
            user?.displayName,
            'Usuario',
          ]) ??
          'Usuario',
      email = _firstNonEmpty([data?['email'] as String?, user?.email]) ?? '—',
      userType = _firstNonEmpty([data?['userType'] as String?]),
      rangerId = _firstNonEmpty([data?['rangerId'] as String?]),
      specialty = _firstNonEmpty([data?['specialty'] as String?]),
      photoUrl = _firstNonEmpty([data?['photoUrl'] as String?, user?.photoURL]);

  final String name;
  final String email;
  final String? userType;
  final String? rangerId;
  final String? specialty;
  final String? photoUrl;

  List<String> get badges => [
    if (userType != null) userType!,
    if (specialty != null) specialty!,
    if (rangerId != null) rangerId!,
  ];

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

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

  static const _userTypes = [
    'Guía Naturalista',
    'Guardaparque',
    'Investigador',
    'Voluntario',
    'Administrador',
  ];
  static const _specialties = [
    'Conservación Marina',
    'Conservación Terrestre',
    'Flora',
    'Fauna',
    'Aves',
    'Reptiles',
    'Educación Ambiental',
  ];

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final auth = AuthService();
    final user = auth.currentUser;
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
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: user != null ? auth.userDoc(user.uid) : null,
                    builder: (context, snap) {
                      final profile = _AccountProfile(snap.data?.data(), user);
                      return _accountCard(eco, profile);
                    },
                  ),
                  const SizedBox(height: 24),
                  _group(eco, 'Perfil Personal', [
                    EcoListRow(
                      icon: Icons.manage_accounts,
                      title: 'Editar Información',
                      trailing: Icon(Icons.chevron_right, color: eco.outline),
                      onTap: () => _openEditProfile(context, user),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _group(eco, 'Seguridad', [
                    EcoListRow(
                      icon: Icons.lock_reset,
                      title: 'Cambiar Contraseña',
                      iconBg: eco.tertiary.withValues(alpha: 0.12),
                      iconColor: eco.tertiary,
                      trailing: Icon(Icons.chevron_right, color: eco.outline),
                      onTap: () => _openChangePassword(context, user),
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
                        onChanged: (v) => setState(() => _pushField = v),
                      ),
                    ),
                    _sep(eco),
                    EcoListRow(
                      icon: Icons.forum,
                      title: 'Mensajes del Muro',
                      subtitle: 'Interacciones con equipo',
                      iconBg: eco.tertiary.withValues(alpha: 0.12),
                      iconColor: eco.tertiary,
                      trailing: EcoSwitch(
                        value: _pushWall,
                        onChanged: (v) => setState(() => _pushWall = v),
                      ),
                    ),
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
                        onChanged: (v) => themeModeNotifier.value = v
                            ? ThemeMode.dark
                            : ThemeMode.light,
                      ),
                    ),
                    _sep(eco),
                    EcoListRow(
                      icon: Icons.language,
                      title: 'Idioma',
                      iconBg: eco.surfaceContainer,
                      iconColor: eco.onSurface,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Español',
                            style: TextStyle(
                              fontSize: 14,
                              color: eco.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: eco.outline),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'ECOGUÍA GALÁPAGOS · V2.4.0',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: eco.outline,
                      ),
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

  Future<void> _openEditProfile(BuildContext context, User? user) async {
    if (user == null) {
      _snack(context, 'No hay una sesión activa.');
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!context.mounted) return;

    final profile = _AccountProfile(doc.data(), user);
    final nameCtrl = TextEditingController(text: profile.name);
    final rangerCtrl = TextEditingController(text: profile.rangerId ?? '');
    var userType = _dropdownValue(profile.userType, _userTypes);
    var specialty = _dropdownValue(profile.specialty, _specialties);
    var saving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final eco = sheetContext.eco;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> save() async {
                if (nameCtrl.text.trim().isEmpty ||
                    rangerCtrl.text.trim().isEmpty) {
                  _snack(sheetContext, 'Completa nombre e ID.');
                  return;
                }
                setSheetState(() => saving = true);
                try {
                  await AuthService().updateAccountProfile(
                    name: nameCtrl.text.trim(),
                    rangerId: rangerCtrl.text.trim(),
                    userType: userType,
                    specialty: specialty,
                  );
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  _snack(context, 'Información actualizada.');
                } catch (e) {
                  if (sheetContext.mounted) {
                    _snack(sheetContext, _authErrorMessage(e));
                  }
                } finally {
                  if (sheetContext.mounted) {
                    setSheetState(() => saving = false);
                  }
                }
              }

              return _settingsSheet(
                eco,
                title: 'Editar Información',
                bottomInset: MediaQuery.of(sheetContext).viewInsets.bottom,
                children: [
                  _sheetTextField(
                    eco,
                    label: 'Nombre completo',
                    icon: Icons.person,
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: 14),
                  _sheetTextField(
                    eco,
                    label: 'ID Guardaparque',
                    icon: Icons.badge,
                    controller: rangerCtrl,
                  ),
                  const SizedBox(height: 14),
                  _sheetDropdown(
                    eco,
                    label: 'Tipo de usuario',
                    icon: Icons.account_circle,
                    value: userType,
                    options: _userTypes,
                    onChanged: (value) => setSheetState(() => userType = value),
                  ),
                  const SizedBox(height: 14),
                  _sheetDropdown(
                    eco,
                    label: 'Especialidad',
                    icon: Icons.science,
                    value: specialty,
                    options: _specialties,
                    onChanged: (value) =>
                        setSheetState(() => specialty = value),
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: 'Guardar Cambios',
                    loading: saving,
                    trailingIcon: Icons.check,
                    onPressed: save,
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameCtrl.dispose();
      rangerCtrl.dispose();
    }
  }

  Future<void> _openChangePassword(BuildContext context, User? user) async {
    if (user == null) {
      _snack(context, 'No hay una sesión activa.');
      return;
    }

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final eco = sheetContext.eco;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> save() async {
                final current = currentCtrl.text;
                final next = newCtrl.text;
                final confirm = confirmCtrl.text;
                if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                  _snack(sheetContext, 'Completa todos los campos.');
                  return;
                }
                if (next.length < 6) {
                  _snack(
                    sheetContext,
                    'La nueva contraseña debe tener 6 caracteres o más.',
                  );
                  return;
                }
                if (next != confirm) {
                  _snack(sheetContext, 'Las contraseñas nuevas no coinciden.');
                  return;
                }

                setSheetState(() => saving = true);
                try {
                  await AuthService().changePassword(
                    currentPassword: current,
                    newPassword: next,
                  );
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  _snack(context, 'Contraseña actualizada.');
                } catch (e) {
                  if (sheetContext.mounted) {
                    _snack(sheetContext, _authErrorMessage(e));
                  }
                } finally {
                  if (sheetContext.mounted) {
                    setSheetState(() => saving = false);
                  }
                }
              }

              return _settingsSheet(
                eco,
                title: 'Cambiar Contraseña',
                bottomInset: MediaQuery.of(sheetContext).viewInsets.bottom,
                children: [
                  _sheetTextField(
                    eco,
                    label: 'Contraseña actual',
                    icon: Icons.lock,
                    controller: currentCtrl,
                    obscure: true,
                  ),
                  const SizedBox(height: 14),
                  _sheetTextField(
                    eco,
                    label: 'Nueva contraseña',
                    icon: Icons.password,
                    controller: newCtrl,
                    obscure: true,
                  ),
                  const SizedBox(height: 14),
                  _sheetTextField(
                    eco,
                    label: 'Confirmar nueva contraseña',
                    icon: Icons.verified_user,
                    controller: confirmCtrl,
                    obscure: true,
                  ),
                  const SizedBox(height: 22),
                  GradientButton(
                    label: 'Actualizar Contraseña',
                    loading: saving,
                    trailingIcon: Icons.check,
                    onPressed: save,
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    }
  }

  String _dropdownValue(String? value, List<String> options) {
    if (value != null && options.contains(value)) return value;
    return options.first;
  }

  Widget _settingsSheet(
    AppColors eco, {
    required String title,
    required double bottomInset,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: eco.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: eco.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: eco.onSurface,
                  ),
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTextField(
    AppColors eco, {
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Cap(label),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(icon, color: eco.outline, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: TextStyle(fontSize: 14, color: eco.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: label,
                    hintStyle: TextStyle(fontSize: 14, color: eco.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sheetDropdown(
    AppColors eco, {
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Cap(label),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(icon, color: eco.outline, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: eco.surfaceContainerLowest,
                    icon: Icon(Icons.expand_more, color: eco.outline),
                    style: TextStyle(
                      fontSize: 14,
                      color: eco.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      for (final option in options)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (next) {
                      if (next != null) onChanged(next);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.eco.primary),
    );
  }

  String _authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'wrong-password' ||
        'invalid-credential' => 'La contraseña actual no es correcta.',
        'weak-password' => 'La nueva contraseña es demasiado débil.',
        'requires-recent-login' =>
          'Vuelve a iniciar sesión e inténtalo de nuevo.',
        'provider-not-password' =>
          error.message ?? 'Esta cuenta no usa contraseña local.',
        _ => error.message ?? 'No se pudo completar la operación.',
      };
    }
    return 'No se pudo completar la operación: $error';
  }

  Widget _accountCard(AppColors eco, _AccountProfile profile) {
    return EcoCard(
      radius: 32,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          _accountAvatar(eco, profile),
          const SizedBox(height: 16),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: eco.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: eco.onSurfaceVariant),
          ),
          if (profile.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in profile.badges.take(3))
                  EcoChip(badge, tone: ChipTone.tertiary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _accountAvatar(AppColors eco, _AccountProfile profile) {
    Widget avatar;
    if (profile.photoUrl != null) {
      avatar = Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(profile.photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      avatar = Avatar(name: profile.name, size: 96, tone: AvatarTone.forest);
    }

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: eco.primary,
              shape: BoxShape.circle,
              border: Border.all(color: eco.surfaceContainerLowest, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _group(AppColors eco, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: eco.onSurfaceVariant,
            ),
          ),
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
