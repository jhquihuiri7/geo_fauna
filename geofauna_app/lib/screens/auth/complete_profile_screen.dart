import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/animations.dart';
import '../../widgets/painters.dart';

/// Pantalla unificada de "completar perfil". Se muestra tras la autenticación
/// (Google o email) cuando el usuario aún no ha llenado los datos obligatorios.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.user.displayName ?? '');
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
                color: eco.primary.withValues(alpha: 0.08), size: 220),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: BlurBlob(
                color: eco.tertiaryContainer.withValues(alpha: 0.30),
                size: 280),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    child: Container(
                    padding: const EdgeInsets.only(left: 16),
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
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -1.2,
                            color: eco.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Necesitamos algunos datos antes de acceder al archivo de monitoreo biológico.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
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
                    padding: const EdgeInsets.all(24),
                    soft: true,
                    child: Column(
                      children: [
                        _field(eco,
                            cap: 'Nombre Completo',
                            icon: Icons.person,
                            child: _input(
                                eco, _nameCtrl, 'Ej. Dr. Julián Castro')),
                        const SizedBox(height: 20),
                        _field(eco,
                            cap: 'ID Guardaparque',
                            icon: Icons.badge,
                            child: _input(eco, _idCtrl, 'GNPS-2024-00X')),
                        const SizedBox(height: 20),
                        _field(eco,
                            cap: 'Tipo de Usuario',
                            icon: Icons.account_circle,
                            child: _dropdown(eco, _userTypes, _userType,
                                (v) => setState(() => _userType = v))),
                        const SizedBox(height: 20),
                        _field(eco,
                            cap: 'Especialidad',
                            icon: Icons.science,
                            child: _dropdown(eco, _specialties, _specialty,
                                (v) => setState(() => _specialty = v))),
                        const SizedBox(height: 24),
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
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => AuthService().signOut(),
                      icon: Icon(Icons.logout, size: 16, color: eco.outline),
                      label: Text('Cerrar sesión',
                          style: TextStyle(color: eco.outline)),
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

  Widget _field(AppColors eco,
      {required String cap, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Cap(cap),
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
              Icon(icon, size: 18, color: eco.outline),
              const SizedBox(width: 12),
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
      style: TextStyle(fontSize: 14, color: eco.onSurface),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: eco.outline, fontSize: 13),
      ),
    );
  }

  Widget _dropdown(AppColors eco, List<String> options, String value,
      ValueChanged<String> onChanged) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.expand_more, color: eco.outline),
        dropdownColor: eco.surfaceContainerLow,
        style: TextStyle(
            fontSize: 14, color: eco.onSurface, fontWeight: FontWeight.w500),
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
