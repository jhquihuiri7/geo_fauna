import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/app_log.dart';
import '../services/local_cache.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/eco_widgets.dart';

const _log = AppLog('PERM');

/// Recuerda que el usuario eligió entrar sin ubicación, para no plantarle la
/// misma pantalla en cada arranque. Siempre puede reintentar desde las
/// tarjetas del clima.
const _skipCache = LocalCache('permission_skip');

enum _Stage { checking, rationale, requesting, blocked, done }

/// Resuelve los permisos antes de entrar a la app, en orden y con contexto.
///
/// Solo se ve cuando hace falta: con la ubicación ya concedida —el caso del
/// día a día— no aparece nada y se entra directo.
///
/// Existe porque el diálogo del sistema saltaba solo, encima de un Dashboard
/// ya pintado y cargando, sin que nadie hubiera explicado para qué. Dos
/// negativas seguidas dejan el permiso en `deniedForever`, y desde ahí el
/// usuario se queda sin clima, sin mapa y sin recorridos hasta que entre a
/// Ajustes a mano.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key, required this.user, required this.child});

  final User user;
  final Widget child;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  _Stage _stage = _Stage.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_evaluate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de Ajustes el permiso puede haber cambiado sin que la app se
    // entere por ningún otro camino.
    if (state == AppLifecycleState.resumed && _stage == _Stage.blocked) {
      unawaited(_evaluate());
    }
  }

  /// Consulta el estado actual sin disparar ningún diálogo.
  Future<void> _evaluate() async {
    final trace = _log.trace('evaluar ubicación');
    try {
      final permission = await trace.step(
        'checkPermission',
        Geolocator.checkPermission,
        describe: (p) => p.name,
      );

      if (_isGranted(permission)) {
        trace.done();
        _enter();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        trace.done();
        _to(_Stage.blocked);
        return;
      }

      final skipped = await _skipCache.read();
      if (skipped != null) {
        trace.note('ya eligió entrar sin ubicación; no se insiste');
        trace.done();
        _enter();
        return;
      }

      trace.done();
      _to(_Stage.rationale);
    } catch (error) {
      // Un fallo consultando el permiso no puede dejar al usuario fuera de su
      // propia app: se entra, y las tarjetas ya saben quejarse solas.
      trace.failed(error);
      _enter();
    }
  }

  Future<void> _request() async {
    _to(_Stage.requesting);
    final trace = _log.trace('pedir ubicación');
    try {
      final permission = await trace.step(
        'requestPermission (diálogo del sistema)',
        Geolocator.requestPermission,
        describe: (p) => p.name,
      );
      trace.done();
      if (_isGranted(permission)) {
        _enter();
      } else if (permission == LocationPermission.deniedForever) {
        _to(_Stage.blocked);
      } else {
        _to(_Stage.rationale);
      }
    } catch (error) {
      trace.failed(error);
      _to(_Stage.rationale);
    }
  }

  Future<void> _skip() async {
    _log.info('el usuario entra sin ubicación');
    await _skipCache.write({'skippedAtMs': nowMs()});
    _enter();
  }

  /// Entra a la app y solo entonces pide el permiso accesorio.
  ///
  /// Las notificaciones van detrás a propósito: primero el permiso del que
  /// depende media app, después el que solo mejora el muro. Antes los dos
  /// salían a la vez desde puntos distintos y se pisaban en pantalla.
  void _enter() {
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
    unawaited(NotificationService.instance.syncDeviceToken(widget.user));
  }

  void _to(_Stage stage) {
    if (!mounted) return;
    setState(() => _stage = stage);
  }

  static bool _isGranted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.done => widget.child,
      _Stage.checking => const _Checking(),
      _Stage.blocked => _Rationale(
        blocked: true,
        busy: false,
        onPrimary: () => unawaited(openLocationSettings()),
        onSkip: () => unawaited(_skip()),
      ),
      _Stage.rationale || _Stage.requesting => _Rationale(
        blocked: false,
        busy: _stage == _Stage.requesting,
        onPrimary: () => unawaited(_request()),
        onSkip: () => unawaited(_skip()),
      ),
    };
  }
}

/// Consultar el permiso son milisegundos; esto casi nunca llega a verse.
class _Checking extends StatelessWidget {
  const _Checking();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Explica para qué sirve el permiso antes de pedirlo, y ofrece la salida a
/// Ajustes cuando el sistema ya no deja volver a preguntar.
class _Rationale extends StatelessWidget {
  const _Rationale({
    required this.blocked,
    required this.busy,
    required this.onPrimary,
    required this.onSkip,
  });

  /// El permiso quedó en `deniedForever`: ya no hay diálogo que mostrar.
  final bool blocked;
  final bool busy;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      backgroundColor: eco.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space6,
            AppSpacing.space6,
            AppSpacing.space6,
            AppSpacing.space5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: eco.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  blocked
                      ? Icons.lock_outline_rounded
                      : Icons.location_on_rounded,
                  size: 34,
                  color: eco.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                blocked
                    ? 'El permiso está bloqueado'
                    : 'GeoFauna necesita tu ubicación',
                style: AppTextStyles.headline.copyWith(color: eco.onSurface),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                blocked
                    ? 'Android ya no deja volver a preguntártelo desde aquí. '
                          'Se reactiva en Ajustes, en Permisos › Ubicación.'
                    : 'Para darte los datos del punto donde estás de verdad, '
                          'y no de un lugar genérico de las islas.',
                style: AppTextStyles.body.copyWith(
                  color: eco.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (!blocked) ...[
                const SizedBox(height: AppSpacing.space6),
                _reason(
                  eco,
                  Icons.wb_sunny_rounded,
                  'Clima, oleaje y marea de tu punto exacto',
                ),
                const SizedBox(height: AppSpacing.space3_5),
                _reason(
                  eco,
                  Icons.place_rounded,
                  'Sitúa tus avistamientos en el mapa',
                ),
                const SizedBox(height: AppSpacing.space3_5),
                _reason(
                  eco,
                  Icons.route_rounded,
                  'Graba tus recorridos de campo',
                ),
                const SizedBox(height: AppSpacing.space6),
                Text(
                  'Solo mientras usas la app. Puedes cambiarlo cuando quieras.',
                  style: AppTextStyles.bodySm.copyWith(color: eco.outline),
                ),
              ],
              const Spacer(),
              GradientButton(
                label: blocked ? 'Abrir Ajustes' : 'Activar ubicación',
                icon: blocked
                    ? Icons.settings_rounded
                    : Icons.my_location_rounded,
                loading: busy,
                onPressed: onPrimary,
              ),
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: TextButton(
                  onPressed: busy ? null : onSkip,
                  child: Text(
                    'Continuar sin ubicación',
                    style: AppTextStyles.button.copyWith(
                      color: eco.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reason(AppColors eco, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 19, color: eco.primary),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: eco.onSurface),
          ),
        ),
      ],
    );
  }
}
