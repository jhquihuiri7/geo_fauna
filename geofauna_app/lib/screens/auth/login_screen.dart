import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/animations.dart';
import '../../widgets/painters.dart';
import '../../pages/auth/forgot_password_page.dart';
import 'signup_screen.dart';

/// Login — port of `LoginScreen` in screens-auth.jsx, wired to Firebase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await AuthService()
          .signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      // AuthWrapper reacts to the auth state change and routes to the shell.
    } on FirebaseAuthException catch (e) {
      _error(e.message ?? 'No se pudo iniciar sesión');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await AuthService().signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _error(e.message ?? 'Error con Google');
    } catch (e) {
      _error('Error con Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String msg) {
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
            top: -120,
            right: -100,
            child: BlurBlob(
                color: eco.primaryFixedDim.withValues(alpha: 0.30), size: 320),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: BlurBlob(
                color: eco.tertiaryContainer.withValues(alpha: 0.40), size: 360),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  // Brand
                  FadeInUp(
                    child: Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: eco.organicGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: eco.primary.withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: -4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.eco, color: Colors.white, size: 42),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'EcoGuía',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1,
                      color: eco.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CONSERVATION ARCHIVE & FIELD REPORT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: eco.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: EcoCard(
                    radius: 36,
                    padding: const EdgeInsets.all(28),
                    soft: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acceso de Investigador',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: eco.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ingrese sus credenciales para acceder al archivo de monitoreo biológico.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: eco.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Cap('Email de usuario'),
                        const SizedBox(height: 8),
                        EcoTextField(
                          icon: Icons.alternate_email,
                          hint: 'investigador@ecoguia.org',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        Cap(
                          'Clave de acceso',
                          action: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage()),
                            ),
                            child: Text(
                              '¿OLVIDÓ SU CLAVE?',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: eco.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        EcoTextField(
                          icon: Icons.lock,
                          hint: '••••••••',
                          controller: _passCtrl,
                          obscure: true,
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Iniciar Sesión',
                          trailingIcon: Icons.arrow_forward,
                          loading: _loading,
                          onPressed: _signIn,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _google,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: BorderSide(color: eco.outlineVariant),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                            foregroundColor: eco.onSurface,
                          ),
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Continuar con Google',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 1,
                          color: eco.outlineVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '¿Aún no forma parte del equipo de monitoreo?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14, color: eco.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignupScreen()),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: eco.secondaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_add,
                                          size: 18,
                                          color: eco.onSecondaryContainer),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Solicitar Registro',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: eco.onSecondaryContainer,
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
                  ),
                  ),
                  const SizedBox(height: 32),
                  Opacity(
                    opacity: 0.6,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        _footerTag(eco, Icons.verified_user, 'ENCRIPTACIÓN SEGURA'),
                        _footerTag(eco, Icons.landscape, 'ARCHIPIÉLAGO GALÁPAGOS'),
                      ],
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

  Widget _footerTag(AppColors eco, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: eco.outline),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: eco.outline,
          ),
        ),
      ],
    );
  }
}
