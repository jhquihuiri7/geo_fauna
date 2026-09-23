/// Tipos de fallo que la UI necesita distinguir, porque la acción que le toca
/// al usuario es distinta en cada uno: encender el GPS, abrir Ajustes, o
/// simplemente esperar a que vuelva la señal.
enum FailureKind {
  gpsOff,
  permissionDenied,
  permissionBlocked,
  network,
  noFix,
  unknown,
}

/// Error de dominio con un mensaje ya redactado para enseñar tal cual.
class AppFailure implements Exception {
  const AppFailure(this.kind, this.message, {this.cause});

  final FailureKind kind;

  /// Texto para el usuario, en español y sin jerga técnica.
  final String message;

  /// Error original. Va al log, no a la pantalla.
  final Object? cause;

  /// Conserva el prefijo `Exception: ` a propósito: `tracking_screen`,
  /// `live_map` y `weather_header` extraen el texto con
  /// `startsWith('Exception: ')`, y quitarlo los dejaría mostrando su mensaje
  /// genérico sin que nada fallara a la vista.
  @override
  String toString() => 'Exception: $message';
}

/// Clasifica cualquier error, incluidos los que no son [AppFailure].
FailureKind failureKindOf(Object error) =>
    error is AppFailure ? error.kind : FailureKind.unknown;
