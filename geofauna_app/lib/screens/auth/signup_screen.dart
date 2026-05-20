import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/painters.dart';

/// Signup — port of `SignupScreen` in screens-auth.jsx, wired to Firebase.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _accepted = true;
  bool _loading = false;
  final String _userType = 'Guía Naturalista';
  final String _specialty = 'Conservación Marina';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      _snack('Completa nombre, correo y contraseña');
      return;
    }
    if (!_accepted) {
      _snack('Debes aceptar el Protocolo de Integridad de Datos');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService().registerWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
      );
      // AuthWrapper routes to the shell on success.
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'No se pudo crear la cuenta');
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
                color: eco.tertiaryContainer.withValues(alpha: 0.30), size: 280),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: eco.primary),
                      ),
                      Text(
                        'EcoGuía',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: eco.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero
                        Container(
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
                                'Registro de\nGuardaparque',
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
                                'Inicie su sesión en el Archivo Orgánico para la preservación del ecosistema de Galápagos.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: eco.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Card
                        EcoCard(
                          radius: 32,
                          padding: const EdgeInsets.all(24),
                          soft: true,
                          child: Column(
                            children: [
                              _field(eco,
                                  cap: 'Tipo de Usuario',
                                  icon: Icons.account_circle,
                                  child: _select(eco, _userType)),
                              const SizedBox(height: 20),
                              _field(eco,
                                  cap: 'Nombre Completo',
                                  icon: Icons.person,
                                  child: _input(eco, _nameCtrl,
                                      'Ej. Dr. Julián Castro')),
                              const SizedBox(height: 20),
                              _field(eco,
                                  cap: 'Correo Institucional',
                                  icon: Icons.mail,
                                  child: _input(eco, _emailCtrl,
                                      'julian.castro@galapagos.gob.ec',
                                      keyboard: TextInputType.emailAddress)),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _field(eco,
                                        cap: 'ID Guardaparque',
                                        icon: Icons.badge,
                                        child: _input(eco, _idCtrl,
                                            'GNPS-2024-00X')),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _field(eco,
                                        cap: 'Especialidad',
                                        icon: Icons.science,
                                        child: _select(eco, _specialty)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _field(eco,
                                  cap: 'Contraseña',
                                  icon: Icons.lock,
                                  child: _input(eco, _passCtrl, '••••••••••••',
                                      obscure: true)),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _accepted,
                                      onChanged: (v) =>
                                          setState(() => _accepted = v ?? false),
                                      activeColor: eco.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: eco.onSurfaceVariant,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Acepto el '),
                                          TextSpan(
                                            text:
                                                'Protocolo de Integridad de Datos',
                                            style: TextStyle(
                                              color: eco.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const TextSpan(
                                              text:
                                                  ' y los términos de uso para el monitoreo de biodiversidad de la Dirección del Parque Nacional Galápagos.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GradientButton(
                                label: 'Crear Cuenta',
                                trailingIcon: Icons.chevron_right,
                                loading: _loading,
                                onPressed: _register,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: eco.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🐢',
                                  style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTADO DEL SISTEMA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: eco.outline,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Operativo · Nodo Puerto Ayora',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: eco.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  fontSize: 14, color: eco.onSurfaceVariant),
                              children: [
                                const TextSpan(text: '¿Ya es miembro? '),
                                TextSpan(
                                  text: 'Iniciar Sesión',
                                  style: TextStyle(
                                    color: eco.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  // tapping anywhere in the row pops back
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Volver a Iniciar Sesión'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  Widget _input(AppColors eco, TextEditingController ctrl, String hint,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14, color: eco.onSurface),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: eco.outline, fontSize: 13),
      ),
    );
  }

  Widget _select(AppColors eco, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                color: eco.onSurface,
                fontWeight: FontWeight.w500),
          ),
        ),
        Icon(Icons.expand_more, color: eco.outline),
      ],
    );
  }
}
