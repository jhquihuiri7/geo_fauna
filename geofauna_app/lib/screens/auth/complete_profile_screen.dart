import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/animations.dart';
import '../../widgets/painters.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

/// Pantalla unificada de "completar perfil". Se muestra tras la autenticación
/// (Google o email) cuando el usuario aún no ha llenado los datos obligatorios.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.user.displayName ?? '',
  );
  final _idCtrl = TextEditingController();

  // Opciones por defecto (editables más adelante).
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

  String _userType = _userTypes.first;
  String _specialty = _specialties.first;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _idCtrl.text.trim().isEmpty) {
      _snack('Completa tu nombre y el ID de Guardaparque');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService().completeProfile(
        uid: widget.user.uid,
        name: _nameCtrl.text.trim(),
        rangerId: _idCtrl.text.trim(),
        userType: _userType,
        specialty: _specialty,
      );
      // AuthWrapper escucha el doc y enruta al AppShell automáticamente.
    } catch (e) {
      _snack('No se pudo guardar el perfil: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: context.eco.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      backgroundColor: eco.surface,
      body: Stack(
        children: [
          Positioned(
            top: 100,
            right: -80,
            child: BlurBlob(
              color: eco.primary.withValues(alpha: 0.08),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: BlurBlob(
              color: eco.tertiaryContainer.withValues(alpha: 0.30),
              size: 280,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space6,
                AppSpacing.space6,
                AppSpacing.space6,
                AppSpacing.space10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    child: Container(
                      padding: const EdgeInsets.only(left: AppSpacing.space4),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: eco.primary, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completa tu\nPerfil',
                            style: AppTextStyles.headline.copyWith(
                              color: eco.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          Text(
                            'Necesitamos algunos datos antes de acceder al archivo de monitoreo biológico.',
                            style: AppTextStyles.body.copyWith(
                              color: eco.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: EcoCard(
                      radius: 32,
                      padding: const EdgeInsets.all(AppSpacing.space6),
                      soft: true,
                      child: Column(
                        children: [
                          _field(
                            eco,
                            cap: 'Nombre Completo',
                            icon: Icons.person,
                            child: _input(
                              eco,
                              _nameCtrl,
                              'Ej. Dr. Julián Castro',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space5),
                          _field(
                            eco,
                            cap: 'ID Guardaparque',
                            icon: Icons.badge,
                            child: _input(eco, _idCtrl, 'GNPS-2024-00X'),
                          ),
                          const SizedBox(height: AppSpacing.space5),
                          _field(
                            eco,
                            cap: 'Tipo de Usuario',
                            icon: Icons.account_circle,
                            child: _dropdown(
                              eco,
                              _userTypes,
                              _userType,
                              (v) => setState(() => _userType = v),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space5),
                          _field(
                            eco,
                            cap: 'Especialidad',
                            icon: Icons.science,
                            child: _dropdown(
                              eco,
                              _specialties,
                              _specialty,
                              (v) => setState(() => _specialty = v),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space6),
                          GradientButton(
                            label: 'Guardar y Continuar',
                            trailingIcon: Icons.chevron_right,
                            loading: _loading,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => AuthService().signOut(),
                      icon: Icon(Icons.logout, size: 16, color: eco.outline),
                      label: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: eco.outline),
                      ),
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

  Widget _field(
    AppColors eco, {
    required String cap,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Cap(cap),
        const SizedBox(height: AppSpacing.space2),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4_5),
          decoration: BoxDecoration(
            color: eco.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: eco.outline),
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }

  Widget _input(AppColors eco, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: AppTextStyles.body.copyWith(color: eco.onSurface),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: AppTextStyles.bodySm.copyWith(color: eco.outline),
      ),
    );
  }

  Widget _dropdown(
    AppColors eco,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.expand_more, color: eco.outline),
        dropdownColor: eco.surfaceContainerLow,
        style: TextStyle(
          fontSize: 14,
          color: eco.onSurface,
          fontWeight: FontWeight.w500,
        ),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
