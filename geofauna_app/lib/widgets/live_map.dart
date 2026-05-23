import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../theme/app_colors.dart';

/// Mapa OpenStreetMap centrado en la ubicación actual del dispositivo, con un
/// marcador en tu posición. Acepta [overlays] (widgets `Positioned`) que se
/// dibujan encima del mapa para conservar los chips del diseño.
class LiveMap extends StatefulWidget {
  const LiveMap({
    super.key,
    this.height = 240,
    this.borderRadius = 32,
    this.zoom = 14,
    this.interactive = true,
    this.overlays = const [],
  });

  final double height;
  final double borderRadius;
  final double zoom;
  final bool interactive;
  final List<Widget> overlays;

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  late Future<UserLocation> _future = LocationService().getCurrentLocation();

  void _retry() =>
      setState(() => _future = LocationService().getCurrentLocation());

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height,
        child: FutureBuilder<UserLocation>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.done &&
                snap.hasError) {
              return _state(
                eco,
                icon: Icons.location_off,
                message: _message(snap.error!),
                action: TextButton(
                    onPressed: _retry, child: const Text('Reintentar')),
              );
            }
            if (!snap.hasData) {
              return _state(
                eco,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: eco.primary),
                ),
                message: 'Centrando el mapa en tu ubicación…',
              );
            }
            final center = LatLng(snap.data!.latitude, snap.data!.longitude);
            return Stack(
              children: [
                Positioned.fill(child: _map(eco, center)),
                ...widget.overlays,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _map(AppColors eco, LatLng center) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: widget.zoom,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.geofauna.app',
          tileProvider: NetworkTileProvider(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 44,
              height: 44,
              alignment: Alignment.topCenter,
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
                child:
                    const Icon(Icons.person_pin, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _state(AppColors eco,
      {IconData? icon, Widget? child, required String message, Widget? action}) {
    return Container(
      color: eco.surfaceContainerLow,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (child != null)
            child
          else if (icon != null)
            Icon(icon, size: 32, color: eco.outline),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: eco.onSurfaceVariant),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  String _message(Object error) {
    final s = error.toString();
    return s.startsWith('Exception: ')
        ? s.substring(11)
        : 'No se pudo cargar el mapa.';
  }
}
