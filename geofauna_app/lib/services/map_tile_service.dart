import 'package:flutter_map/flutter_map.dart';

/// Configuracion central de tiles para todos los mapas de la app.
///
/// Este punto unico facilita cambiar de tiles online a una fuente offline
/// sin tocar cada pantalla que renderiza un mapa.
class MapTileService {
  const MapTileService._();

  static const tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackageName = 'com.geofauna.app';

  static TileLayer baseTileLayer() {
    return TileLayer(
      urlTemplate: tileUrlTemplate,
      userAgentPackageName: userAgentPackageName,
      tileProvider: NetworkTileProvider(),
    );
  }
}
