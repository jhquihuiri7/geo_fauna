import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/map_tile_service.dart';
import '../theme/app_colors.dart';

/// Un avistamiento a dibujar sobre el mapa (categoría normalizada + ubicación).
class MapSighting {
  const MapSighting({
    required this.point,
    required this.categoryKey,
    this.species,
    this.placeLabel,
  });

  /// Clave de categoría ya normalizada: fauna / flora / incident / trash / otros.
  final String categoryKey;
  final LatLng point;
  final String? species;
  final String? placeLabel;
}

IconData mapCategoryIcon(String key) {
  return switch (key) {
    'fauna' => Icons.pets_rounded,
    'flora' => Icons.local_florist_rounded,
    'incident' => Icons.warning_amber_rounded,
    'trash' => Icons.delete_rounded,
    _ => Icons.place_rounded,
  };
}

Color mapCategoryColor(String key) {
  return switch (key) {
    'fauna' => const Color(0xFF16A34A),
    'flora' => const Color(0xFF0D9488),
    'incident' => const Color(0xFFF59E0B),
    'trash' => const Color(0xFF6366F1),
    _ => const Color(0xFF64748B),
  };
}

String mapCategoryLabel(String key) {
  return switch (key) {
    'fauna' => 'Fauna',
    'flora' => 'Flora',
    'incident' => 'Incidente',
    'trash' => 'Basura',
    _ => 'Otros',
  };
}

/// Mapa OpenStreetMap centrado en la ubicación actual del dispositivo, con un
/// marcador en tu posición. Acepta [overlays] (widgets `Positioned`) que se
/// dibujan encima del mapa para conservar los chips del diseño, y una lista de
/// [sightings] que se agrupan en clústeres y se separan al hacer zoom.
class LiveMap extends StatefulWidget {
  const LiveMap({
    super.key,
    this.height = 240,
    this.borderRadius = 32,
    this.zoom = 14,
    this.interactive = true,
    this.overlays = const [],
    this.sightings = const [],
    this.expandable = false,
    this.fullscreenTitle,
    this.location,
  });

  final double height;
  final double borderRadius;
  final double zoom;
  final bool interactive;
  final List<Widget> overlays;
  final List<MapSighting> sightings;

  /// Ubicación a mostrar/centrar en lugar del GPS. Cuando es `null` el mapa usa
  /// la posición actual del dispositivo; cuando se provee (p. ej. una ubicación
  /// editada en el mapa) el marcador se mueve allí y la cámara se recentra.
  final LatLng? location;

  /// Muestra un botón para abrir el mapa a pantalla completa.
  final bool expandable;
  final String? fullscreenTitle;

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
        // Con una ubicación explícita no necesitamos el GPS: dibujamos el mapa
        // directamente centrado en ese punto.
        child: widget.location != null
            ? _map(eco, widget.location!)
            : FutureBuilder<UserLocation>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.done &&
                      snap.hasError) {
                    return _state(
                      eco,
                      icon: Icons.location_off,
                      message: _message(snap.error!),
                      action: TextButton(
                        onPressed: _retry,
                        child: const Text('Reintentar'),
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return _state(
                      eco,
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: eco.primary,
                        ),
                      ),
                      message: 'Centrando el mapa en tu ubicación…',
                    );
                  }
                  final lat = snap.data!.latitude;
                  final lng = snap.data!.longitude;

                  if (!lat.isFinite || !lng.isFinite) {
                    return _state(
                      eco,
                      icon: Icons.location_off,
                      message: 'Ubicación inválida. Reinicia el GPS.',
                      action: TextButton(
                        onPressed: _retry,
                        child: const Text('Reintentar'),
                      ),
                    );
                  }

                  return _map(eco, LatLng(lat, lng));
                },
              ),
      ),
    );
  }

  Widget _map(AppColors eco, LatLng center) {
    return Stack(
      children: [
        Positioned.fill(
          child: SightingMapView(
            center: center,
            sightings: widget.sightings,
            initialZoom: widget.zoom,
            interactive: widget.interactive,
          ),
        ),
        ...widget.overlays,
        if (widget.expandable)
          Positioned(
            top: 16,
            right: 16,
            child: _ExpandButton(onTap: () => _openFullscreen(context, center)),
          ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, LatLng center) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenSightingMap(
          center: center,
          sightings: widget.sightings,
          title: widget.fullscreenTitle,
        ),
      ),
    );
  }

  Widget _state(
    AppColors eco, {
    IconData? icon,
    Widget? child,
    required String message,
    Widget? action,
  }) {
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
              color: eco.onSurfaceVariant,
            ),
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

/// Mapa con marcadores de avistamientos agrupados por zoom. Llena el espacio de
/// su padre (usar dentro de `Positioned.fill`, `Expanded`, etc.).
class SightingMapView extends StatefulWidget {
  const SightingMapView({
    super.key,
    required this.center,
    this.sightings = const [],
    this.initialZoom = 14,
    this.interactive = true,
  });

  final LatLng center;
  final List<MapSighting> sightings;
  final double initialZoom;
  final bool interactive;

  @override
  State<SightingMapView> createState() => _SightingMapViewState();
}

class _SightingMapViewState extends State<SightingMapView> {
  final MapController _controller = MapController();
  late double _zoom = widget.initialZoom;
  MapSighting? _selected;

  @override
  void didUpdateWidget(covariant SightingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El mapa solo aplica `initialCenter` la primera vez; si el centro cambia
    // (p. ej. al editar la ubicación) movemos la cámara al nuevo punto.
    if (widget.center != oldWidget.center &&
        widget.center.latitude.isFinite &&
        widget.center.longitude.isFinite) {
      _controller.move(widget.center, _zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Agrupa los avistamientos en una rejilla cuyo tamaño (en grados) se reduce
  /// al acercar, de modo que los clústeres se separan al hacer zoom.
  List<_Cluster> _clusters(double zoom) {
    final list = widget.sightings;
    if (list.isEmpty) return const [];
    final cell = _cellDegrees(zoom);
    final groups = <String, List<MapSighting>>{};
    for (final s in list) {
      // Defensa: ignora coordenadas no finitas para no romper flutter_map.
      if (!s.point.latitude.isFinite || !s.point.longitude.isFinite) continue;
      final gx = (s.point.longitude / cell).floor();
      final gy = (s.point.latitude / cell).floor();
      groups.putIfAbsent('$gx:$gy', () => <MapSighting>[]).add(s);
    }
    final result = <_Cluster>[];
    for (final group in groups.values) {
      if (group.length == 1) {
        result.add(_Cluster(point: group.first.point, items: group));
        continue;
      }
      var lat = 0.0;
      var lng = 0.0;
      for (final s in group) {
        lat += s.point.latitude;
        lng += s.point.longitude;
      }
      result.add(
        _Cluster(
          point: LatLng(lat / group.length, lng / group.length),
          items: group,
        ),
      );
    }
    return result;
  }

  /// ~70 px de radio de agrupación traducidos a grados para el zoom actual.
  double _cellDegrees(double zoom) {
    const clusterPixels = 70.0;
    return clusterPixels * 360 / (256 * math.pow(2, zoom));
  }

  void _zoomInto(_Cluster cluster) {
    final point = cluster.point;
    if (!point.latitude.isFinite || !point.longitude.isFinite) return;
    setState(() => _selected = null);
    _controller.move(point, math.min(_zoom + 2, 18));
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;

    // Validación defensiva del centro
    if (!widget.center.latitude.isFinite || !widget.center.longitude.isFinite) {
      return Container(
        color: eco.surfaceContainerLow,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 32, color: eco.outline),
            const SizedBox(height: 12),
            Text(
              'Ubicación inválida',
              textAlign: TextAlign.center,
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

    final clusters = _clusters(_zoom);
    final markers = <Marker>[];

    for (final cluster in clusters) {
      if (cluster.isSingle) {
        final sighting = cluster.first;
        markers.add(
          Marker(
            point: sighting.point,
            width: 40,
            height: 48,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => setState(() => _selected = sighting),
              child: _CategoryPin(
                categoryKey: sighting.categoryKey,
                selected: _selected?.point == sighting.point,
              ),
            ),
          ),
        );
      } else {
        markers.add(
          Marker(
            point: cluster.point,
            width: 46,
            height: 46,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _zoomInto(cluster),
              child: _ClusterBubble(count: cluster.count, color: eco.primary),
            ),
          ),
        );
      }
    }

    markers.add(
      Marker(
        point: widget.center,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: _UserPin(color: eco.primary),
      ),
    );

    final selected = _selected;
    if (selected != null) {
      markers.add(
        Marker(
          point: selected.point,
          width: 220,
          height: 96,
          alignment: Alignment.bottomCenter,
          child: Align(
            alignment: Alignment.topCenter,
            child: _SightingPopup(sighting: selected),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.initialZoom,
        minZoom: 2,
        maxZoom: 19,
        onTap: (_, __) {
          if (_selected != null) setState(() => _selected = null);
        },
        onPositionChanged: (camera, hasGesture) {
          if ((camera.zoom - _zoom).abs() > 0.01) {
            setState(() => _zoom = camera.zoom);
          }
        },
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.flingAnimation
              : InteractiveFlag.none,
        ),
      ),
      children: [
        MapTileService.baseTileLayer(),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _Cluster {
  const _Cluster({required this.point, required this.items});

  final LatLng point;
  final List<MapSighting> items;

  bool get isSingle => items.length == 1;
  int get count => items.length;
  MapSighting get first => items.first;
}

class _CategoryPin extends StatelessWidget {
  const _CategoryPin({required this.categoryKey, this.selected = false});

  final String categoryKey;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = mapCategoryColor(categoryKey);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            mapCategoryIcon(categoryKey),
            color: Colors.white,
            size: 18,
          ),
        ),
        CustomPaint(size: const Size(14, 9), painter: _PinTail(color)),
      ],
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UserPin extends StatelessWidget {
  const _UserPin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.person_pin, color: Colors.white, size: 22),
    );
  }
}

class _SightingPopup extends StatelessWidget {
  const _SightingPopup({required this.sighting});

  final MapSighting sighting;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    final color = mapCategoryColor(sighting.categoryKey);
    final label = mapCategoryLabel(sighting.categoryKey);
    final species = sighting.species;
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              mapCategoryIcon(sighting.categoryKey),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  species ?? sighting.placeLabel ?? 'Avistamiento',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: eco.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTail extends CustomPainter {
  const _PinTail(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTail oldDelegate) =>
      oldDelegate.color != color;
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Material(
      color: eco.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.fullscreen_rounded, size: 22, color: eco.onSurface),
        ),
      ),
    );
  }
}

class _FullscreenSightingMap extends StatelessWidget {
  const _FullscreenSightingMap({
    required this.center,
    required this.sightings,
    this.title,
  });

  final LatLng center;
  final List<MapSighting> sightings;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SightingMapView(
              center: center,
              sightings: sightings,
              initialZoom: 14,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Material(
                      color: eco.surfaceContainerLowest,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: eco.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(width: 12),
                      _TitlePill(title: title!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final eco = context.eco;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: eco.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: eco.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
