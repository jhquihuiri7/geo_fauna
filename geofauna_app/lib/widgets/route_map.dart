import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/map_tile_service.dart';
import '../theme/app_colors.dart';

/// Mapa estático y "bonito" de un recorrido ya grabado: dibuja la ruta completa
/// como polilínea sobre OpenStreetMap, con marcadores de inicio y fin y la
/// cámara ajustada a los límites del trazo. Se usa tanto en el muro como en la
/// card de la agenda, por eso es no interactivo por defecto.
class RouteMapPreview extends StatelessWidget {
  const RouteMapPreview({
    super.key,
    required this.points,
    this.height = 240,
    this.borderRadius = 28,
    this.interactive = false,
  });

  /// Puntos del recorrido en orden cronológico.
  final List<LatLng> points;
  final double height;
  final double borderRadius;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;

    if (points.isEmpty) {
      return _placeholder(eco, 'Recorrido sin puntos GPS');
    }

    // Filtra puntos con coordenadas inválidas
    final validPoints = [
      for (final p in points)
        if (p.latitude.isFinite && p.longitude.isFinite) p,
    ];

    if (validPoints.isEmpty) {
      return _placeholder(eco, 'Coordenadas GPS inválidas');
    }

    final flags = interactive
        ? (InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom)
        : InteractiveFlag.none;

    // Un solo punto: centramos en él; varios: ajustamos a los límites.
    final cameraFit = validPoints.length == 1
        ? null
        : CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(validPoints),
            padding: const EdgeInsets.all(28),
            maxZoom: 17,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: validPoints.first,
            initialZoom: 15,
            initialCameraFit: cameraFit,
            interactionOptions: InteractionOptions(flags: flags),
          ),
          children: [
            MapTileService.baseTileLayer(),
            if (validPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: validPoints,
                    strokeWidth: 2.5,
                    color: eco.primary,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white.withValues(alpha: 0.85),
                    pattern: StrokePattern.dashed(segments: const [6, 6]),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: validPoints.first,
                  width: 10,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: eco.primary, width: 2),
                    ),
                  ),
                ),
                Marker(
                  point: validPoints.last,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: eco.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: eco.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppColors eco, String message) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: eco.surfaceContainerLow,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, color: eco.outline, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: eco.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
