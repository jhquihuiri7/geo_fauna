import 'dart:async';

/// Cada cuánto avisa el watchdog de que un paso sigue sin resolverse.
const Duration _watchdogInterval = Duration(seconds: 5);

/// Logger con correlación por intento para seguir flujos asíncronos desde el
/// dispositivo. Cada línea lleva el prefijo `[GEO]`, así que basta con:
///
/// ```
/// adb logcat | grep GEO
/// ```
///
/// Funciona igual en debug y en release: eso condiciona cómo emite, ver [_emit].
class AppLog {
  const AppLog(this.tag);

  /// Identifica el subsistema (`LOC`, `WEATHER`, …) dentro del prefijo `[GEO]`.
  final String tag;

  static int _lastTraceId = 0;

  /// Abre un intento numerado. El número se repite en todas sus líneas, para
  /// poder seguir un intento concreto cuando hay varios en vuelo —Dashboard y
  /// Agenda comparten el mismo flujo— o cuando el usuario pulsa "Reintentar".
  LogTrace trace(String flow) => LogTrace._(tag, flow, ++_lastTraceId);

  void info(String message) => _emit(tag, message);

  void failure(String message, Object error, [StackTrace? stack]) =>
      _emit(tag, message, error: error, stack: stack);
}

/// Un intento concreto de un flujo, obtenido con [AppLog.trace].
class LogTrace {
  LogTrace._(this._tag, this._flow, this._id) {
    _emit(_tag, '#$_id $_flow: inicio');
  }

  final String _tag;
  final String _flow;
  final int _id;
  final Stopwatch _elapsed = Stopwatch()..start();

  /// Ejecuta [action] dejando rastro de inicio, fin y duración.
  ///
  /// Si falla, registra el error con su stack y lo relanza intacto: esto es
  /// instrumentación, no manejo de errores, y quien llama debe seguir viendo la
  /// excepción original.
  ///
  /// [describe] anota el resultado (coordenadas, código HTTP) sin volcar el
  /// objeto entero al log.
  Future<T> step<T>(
    String name,
    Future<T> Function() action, {
    String Function(T value)? describe,
  }) async {
    final started = _elapsed.elapsedMilliseconds;
    _emit(_tag, '#$_id $name: ejecutando…');

    // Un paso colgado no emite nada por sí mismo, que es justo el caso difícil
    // de diagnosticar. El watchdog lo delata hasta que resuelve.
    var waited = Duration.zero;
    final watchdog = Timer.periodic(_watchdogInterval, (_) {
      waited += _watchdogInterval;
      _emit(_tag, '#$_id $name: SIGUE PENDIENTE tras ${waited.inSeconds}s');
    });

    try {
      final value = await action();
      final took = _elapsed.elapsedMilliseconds - started;
      final detail = describe == null ? '' : ' -> ${describe(value)}';
      _emit(_tag, '#$_id $name: ok en ${took}ms$detail');
      return value;
    } catch (error, stack) {
      final took = _elapsed.elapsedMilliseconds - started;
      _emit(
        _tag,
        '#$_id $name: FALLÓ tras ${took}ms',
        error: error,
        stack: stack,
      );
      rethrow;
    } finally {
      watchdog.cancel();
    }
  }

  /// Igual que [step] para trabajo síncrono, como parsear una respuesta. No
  /// lleva watchdog porque un paso síncrono no puede quedarse pendiente.
  T stepSync<T>(
    String name,
    T Function() action, {
    String Function(T value)? describe,
  }) {
    final started = _elapsed.elapsedMilliseconds;
    try {
      final value = action();
      final took = _elapsed.elapsedMilliseconds - started;
      final detail = describe == null ? '' : ' -> ${describe(value)}';
      _emit(_tag, '#$_id $name: ok en ${took}ms$detail');
      return value;
    } catch (error, stack) {
      _emit(_tag, '#$_id $name: FALLÓ', error: error, stack: stack);
      rethrow;
    }
  }

  /// Anota algo dentro del intento sin envolver una operación.
  void note(String message) => _emit(_tag, '#$_id $message');

  void done() => _emit(
    _tag,
    '#$_id $_flow: completo en ${_elapsed.elapsedMilliseconds}ms',
  );

  /// Cierra el intento como fallido. No repite el stack: si el error vino de un
  /// [step] ya quedó registrado ahí con todo el detalle.
  void failed(Object error) => _emit(
    _tag,
    '#$_id $_flow: ABORTADO tras ${_elapsed.elapsedMilliseconds}ms -> $error',
  );
}

/// Emite una línea de log.
///
/// Usa `print` a propósito, y no las alternativas habituales:
///
/// - `developer.log` depende del VM service, que no existe en un build AOT, así
///   que no emite absolutamente nada en release — justo donde hace falta
///   diagnosticar el APK instalado.
/// - `debugPrint` estrangula la salida para no saturar el buffer de Android, lo
///   que retrasa y reordena líneas y arruina la lectura de los tiempos.
///
/// Cada línea sale por separado porque `__android_log_write` trunca alrededor de
/// los 4000 caracteres, y un stack trace completo se pasa de largo.
void _emit(String tag, String message, {Object? error, StackTrace? stack}) {
  final buffer = StringBuffer('[GEO][$tag] $message');
  if (error != null) buffer.write('\n  error: $error');
  if (stack != null) buffer.write('\n  stack: $stack');

  for (final line in buffer.toString().split('\n')) {
    // ignore: avoid_print
    print(line);
  }
}
