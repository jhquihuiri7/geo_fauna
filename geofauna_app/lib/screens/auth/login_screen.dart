import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/eco_widgets.dart';
import '../../widgets/animations.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/painters.dart';
import '../../pages/auth/forgot_password_page.dart';
import 'signup_screen.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

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
      await AuthService().signInWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
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
              color: eco.primaryFixedDim.withValues(alpha: 0.30),
              size: 320,
            ),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: BlurBlob(
              color: eco.tertiaryContainer.withValues(alpha: 0.40),
              size: 360,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space6,
                32,
                AppSpacing.space6,
                32,
              ),
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLogo,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: eco.primary.withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: -4,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const TortugaTopoMark.onFill(size: 52),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space5),
                  Text(
                    'EcoGuía',
                    style: AppTextStyles.display.copyWith(color: eco.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'CONSERVATION ARCHIVE & FIELD REPORT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: eco.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space10),
                  // Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: EcoCard(
                      radius: 36,
                      padding: const EdgeInsets.all(AppSpacing.space7),
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
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            'Ingrese sus credenciales para acceder al archivo de monitoreo biológico.',
                            style: AppTextStyles.body.copyWith(
                              color: eco.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space6),
                          const Cap('Email de usuario'),
                          const SizedBox(height: AppSpacing.space2),
                          EcoTextField(
                            icon: Icons.alternate_email,
                            hint: 'investigador@ecoguia.org',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.space5),
                          Cap(
                            'Clave de acceso',
                            action: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              ),
                              child: Text(
                                '¿OLVIDÓ SU CLAVE?',
                                style: AppTextStyles.cap.copyWith(
                                  color: eco.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space2),
                          EcoTextField(
                            icon: Icons.lock,
                            hint: '••••••••',
                            controller: _passCtrl,
                            obscure: true,
                          ),
                          const SizedBox(height: AppSpacing.space7),
                          GradientButton(
                            label: 'Iniciar Sesión',
                            trailingIcon: Icons.arrow_forward,
                            loading: _loading,
                            onPressed: _signIn,
                          ),
                          const SizedBox(height: AppSpacing.space4),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _google,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: BorderSide(color: eco.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              foregroundColor: eco.onSurface,
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text(
                              'Continuar con Google',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space6),
                          Container(
                            height: 1,
                            color: eco.outlineVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.space5),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '¿Aún no forma parte del equipo de monitoreo?',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: eco.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.space3),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.space6,
                                      vertical: AppSpacing.space3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: eco.secondaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_add,
                                          size: 18,
                                          color: eco.onSecondaryContainer,
                                        ),
                                        const SizedBox(
                                          width: AppSpacing.space2,
                                        ),
                                        Text(
                                          'Solicitar Registro',
                                          style: AppTextStyles.bodyStrong
                                              .copyWith(
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
                        _footerTag(
                          eco,
                          Icons.verified_user,
                          'ENCRIPTACIÓN SEGURA',
                        ),
                        _footerTag(
                          eco,
                          Icons.landscape,
                          'ARCHIPIÉLAGO GALÁPAGOS',
                        ),
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
