import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';

/// Integridad — data integrity protocol (screens-extra.jsx).
class IntegridadScreen extends StatelessWidget {
  const IntegridadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      backgroundColor: eco.surface,
      body: SafeArea(
        child: Column(
          children: [
            SubHeader(
              title: 'EcoGuía Protocol',
              onBack: () => Navigator.pop(context),
              leadingIcon: Icons.menu,
              trailing: const Avatar(
                  size: 36, tone: AvatarTone.forest, emoji: '🦫'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  GradientPanel(
                    radius: 32,
                    dots: true,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Protocolo de\nIntegridad de Datos',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                letterSpacing: -1,
                                color: Colors.white)),
                        SizedBox(height: 12),
                        Text(
                            'Estableciendo el estándar para la recolección de datos ambientales precisos en el archipiélago.',
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: eco.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.shield, color: eco.tertiary),
                      ),
                      const SizedBox(width: 12),
                      Text('Integridad de datos',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: eco.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'En esta app, cada registro contribuye al monitoreo y conservación del entorno. Para asegurar la calidad de la información:',
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: eco.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  _protocolItem(eco, Icons.location_on,
                      'Tus registros incluyen ubicación GPS automática'),
                  const SizedBox(height: 12),
                  _protocolItem(eco, Icons.photo_camera,
                      'Puedes añadir fotos como evidencia'),
                  const SizedBox(height: 12),
                  _protocolItem(eco, Icons.rule,
                      'Los datos se validan comparando registros de otros usuarios'),
                  const SizedBox(height: 12),
                  _protocolItem(eco, Icons.trending_up,
                      'Se analiza la coherencia de la información en el tiempo'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: eco.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: eco.onSurface),
                        children: [
                          TextSpan(
                              text:
                                  'Esto permite generar datos confiables y útiles',
                              style: TextStyle(
                                  color: eco.primary,
                                  fontWeight: FontWeight.w800)),
                          const TextSpan(
                              text:
                                  ' para la comunidad, la investigación y la gestión ambiental.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.key, color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 12),
                      Text('Uso responsable',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: eco.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bullet(eco, Icons.check_circle,
                      'Registra información real y verificable'),
                  const SizedBox(height: 12),
                  _bullet(eco, Icons.visibility_off,
                      'Evita compartir ubicaciones sensibles de especies vulnerables'),
                  const SizedBox(height: 12),
                  _bullet(eco, Icons.eco,
                      'Usa la app con fines ambientales y profesionales'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 20),
                    decoration: BoxDecoration(
                      color: eco.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              child: const Text('🌱',
                                  style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            Text('Compromiso',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: eco.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Al usar la app, contribuyes a una red de monitoreo basada en ciencia ciudadana, ayudando a proteger la biodiversidad.',
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: eco.onSurfaceVariant)),
                      ],
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

  Widget _protocolItem(AppColors eco, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: eco.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: eco.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 14, height: 1.3, color: eco.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _bullet(AppColors eco, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: eco.tertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 14, height: 1.5, color: eco.onSurfaceVariant)),
        ),
      ],
    );
  }
}
