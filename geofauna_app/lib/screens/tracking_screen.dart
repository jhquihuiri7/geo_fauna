import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/field_data_service.dart';
import '../services/location_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eco_widgets.dart';

/// Pantalla de grabación de un recorrido de campo: mapa en vivo con la ruta
/// dibujada, métricas en tiempo real y controles de pausa/fin.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({
    super.key,
    this.tourId,
    this.tourName,
    this.tourType,
    this.resume = false,
    this.overwriteTrackId,
  });

  /// Tour de la agenda asociado (opcional: también se puede grabar libre).
  final String? tourId;
  final String? tourName;
  final String? tourType;

  /// `true` cuando se reanuda una sesión recuperada tras cerrar la app.
  final bool resume;

  /// Id de un recorrido previo a sobrescribir: al grabar de nuevo se reutiliza
  /// este id para reemplazar el track (y su publicación) anteriores.
  final String? overwriteTrackId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _service = TrackingService.instance;
  final _mapController = MapController();

  Timer? _ticker;
  LatLng? _initialCenter;
  bool _mapReady = false;
  bool _follow = true;
  bool _starting = true;
  bool _finishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.session.addListener(_onSession);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _service.session.removeListener(_onSession);
    _ticker?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Centro inicial: último punto si reanudamos, o la ubicación actual.
    final existing = _service.session.value?.lastPoint;
    if (existing != null) {
      _initialCenter = existing.latLng;
    } else {
      try {
        final loc = await LocationService().getCurrentLocation();
        _initialCenter = LatLng(loc.latitude, loc.longitude);
      } catch (_) {
        _initialCenter = const LatLng(-0.7437, -90.3136); // Galápagos fallback
      }
    }
    if (!mounted) return;
    setState(() {});

    try {
      if (widget.resume) {
        await _service.resume();
      } else if (!_service.isActive) {
        await _service.start(
          tourId: widget.tourId,
          tourName: widget.tourName,
          tourType: widget.tourType,
          trackId: widget.overwriteTrackId,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _cleanError(error));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _onSession() {
    final last = _service.session.value?.lastPoint;
    if (last != null && _follow && _mapReady) {
      _mapController.move(last.latLng, _mapController.camera.zoom);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final session = _service.session.value;

    return Scaffold(
      backgroundColor: eco.surface,
      body: Stack(
        children: [
          if (_initialCenter != null) _buildMap(eco, session) else _loading(eco),
          // Degradado superior para legibilidad del HUD.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      eco.surface.withValues(alpha: 0.92),
                      eco.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(eco, session),
                _metricsHud(eco, session),
                const Spacer(),
                if (_error != null) _errorCard(eco),
                _controls(eco, session),
              ],
            ),
          ),
          if (!_follow)
            Positioned(
              right: 16,
              bottom: 190,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: eco.surfaceContainerLowest,
                foregroundColor: eco.primary,
                onPressed: () {
                  final last = _service.session.value?.lastPoint;
                  setState(() => _follow = true);
                  if (last != null && _mapReady) {
                    _mapController.move(last.latLng, 16);
                  }
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Widget _loading(AppColors eco) {
    return Container(
      color: eco.surfaceContainerLow,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: eco.primary),
          const SizedBox(height: 14),
          Text(
            'Obteniendo señal GPS…',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: eco.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(AppColors eco, TrackingSession? session) {
    final points = [for (final p in session?.points ?? const <TrackPoint>[]) p.latLng];
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter!,
        initialZoom: 16,
        onMapReady: () => _mapReady = true,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _follow) setState(() => _follow = false);
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.geofauna.app',
          tileProvider: NetworkTileProvider(),
        ),
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 6,
                color: eco.primary,
                borderStrokeWidth: 2,
                borderColor: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (points.isNotEmpty)
              Marker(
                point: points.first,
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: eco.primary, width: 4),
                  ),
                ),
              ),
            if (points.isNotEmpty)
              Marker(
                point: points.last,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: eco.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: eco.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _topBar(AppColors eco, TrackingSession? session) {
    final recording = session?.isRecording ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: _onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session?.tourName ?? 'Recorrido libre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: eco.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: recording ? eco.error : eco.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      recording ? 'Grabando' : 'En pausa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: eco.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsHud(AppColors eco, TrackingSession? session) {
    final distance = session?.distanceMeters ?? 0;
    final duration = session?.movingDuration() ?? Duration.zero;
    final avg = session?.avgSpeedMps() ?? 0;
    final current = session?.currentSpeedMps ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: EcoCard(
        radius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            _metric(eco, 'DISTANCIA', _formatDistance(distance)),
            _divider(eco),
            _metric(eco, 'TIEMPO', _formatDuration(duration)),
            _divider(eco),
            _metric(eco, 'VEL. ACT.', _formatSpeed(current)),
            _divider(eco),
            _metric(eco, 'VEL. MED.', _formatSpeed(avg)),
          ],
        ),
      ),
    );
  }

  Widget _metric(AppColors eco, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: eco.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: eco.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppColors eco) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: eco.outlineVariant,
    );
  }

  Widget _errorCard(AppColors eco) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: EcoCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded, color: eco.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: eco.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(AppColors eco, TrackingSession? session) {
    final recording = session?.isRecording ?? false;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: _secondaryButton(
              eco,
              icon: recording ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: recording ? 'Pausar' : 'Reanudar',
              onTap: _starting
                  ? null
                  : () async {
                      if (recording) {
                        _service.pause();
                      } else {
                        try {
                          await _service.resume();
                        } catch (error) {
                          if (mounted) {
                            setState(() => _error = _cleanError(error));
                          }
                        }
                      }
                    },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GradientButton(
              label: 'Finalizar',
              icon: Icons.flag_rounded,
              loading: _finishing,
              onPressed: _starting ? null : _confirmFinish,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryButton(
    AppColors eco, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: eco.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: eco.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: eco.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: eco.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onBack() async {
    if (!_service.isActive) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    // No abandonamos en silencio una grabación: dejamos que siga en segundo
    // plano y avisamos. El usuario debe finalizar para guardarla.
    final eco = context.eco;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'El recorrido sigue grabándose. Finalízalo para guardarlo.',
        ),
        backgroundColor: eco.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmFinish() async {
    final eco = context.eco;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar recorrido'),
        content: const Text(
          '¿Deseas finalizar y guardar este recorrido? Ya no podrás reanudarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: eco.primary),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _finishing = true);
    try {
      final summary = await _service.stop();
      if (!mounted) return;
      await _showSummary(summary);
    } catch (error) {
      if (mounted) {
        setState(() {
          _finishing = false;
          _error = _cleanError(error);
        });
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showSummary(TrackSummary summary) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: context.eco.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _SummarySheet(summary: summary),
    );
  }

  static String _cleanError(Object error) {
    final s = error.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

class _SummarySheet extends StatefulWidget {
  const _SummarySheet({required this.summary});

  final TrackSummary summary;

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  bool _publishing = false;
  bool _published = false;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final s = widget.summary;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: eco.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: eco.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    s.saved ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
                    color: eco.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Recorrido finalizado!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: eco.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.saved
                            ? (s.tourName ?? 'Recorrido libre')
                            : 'Se subirá automáticamente al recuperar señal.',
                        style: TextStyle(
                          fontSize: 13,
                          color: eco.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _summaryStat(eco, 'Distancia',
                    _formatDistance(s.distanceMeters)),
                _summaryStat(eco, 'Tiempo',
                    _formatDuration(s.movingDuration)),
                _summaryStat(eco, 'Vel. máx.', _formatSpeed(s.maxSpeedMps)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${s.points.length} puntos GPS registrados',
              style: TextStyle(fontSize: 12, color: eco.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            if (_published)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: eco.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Publicado en el muro',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: eco.primary,
                  ),
                ),
              )
            else
              GradientButton(
                label: _publishing ? 'Publicando…' : 'Publicar en el muro',
                icon: Icons.public_rounded,
                loading: _publishing,
                onPressed: (!s.saved || s.points.isEmpty) ? null : _publishToWall,
              ),
            if (!s.saved && !_published) ...[
              const SizedBox(height: 8),
              Text(
                'Podrás publicarlo en el muro cuando el recorrido se suba.',
                style: TextStyle(fontSize: 12, color: eco.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_published ? 'Listo' : 'Ahora no'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(AppColors eco, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: eco.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: eco.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishToWall() async {
    setState(() => _publishing = true);
    final s = widget.summary;
    try {
      await FieldDataService().publishTrackToWall(
        trackId: s.trackId,
        startedAt: s.startedAt,
        movingSeconds: s.movingDuration.inSeconds,
        distanceMeters: s.distanceMeters,
        maxSpeedMps: s.maxSpeedMps,
        points: [for (final p in s.points) p.toJson()],
        tourName: s.tourName,
      );
      if (!mounted) return;
      setState(() => _published = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recorrido publicado en el muro.'),
          backgroundColor: context.eco.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo publicar el recorrido en el muro.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }
}

// ── formateadores compartidos ──────────────────────────────────────────────

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

String _formatSpeed(double mps) {
  final kmh = mps * 3.6;
  return '${kmh.toStringAsFixed(1)} km/h';
}
