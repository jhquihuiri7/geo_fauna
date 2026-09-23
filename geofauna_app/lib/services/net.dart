import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_log.dart';
import 'failures.dart';

/// Cuánto esperamos una respuesta antes de darla por perdida.
///
/// Android no cierra un socket colgado hasta pasados varios minutos, así que
/// sin este límite una petición lanzada durante un corte de DNS deja la
/// tarjeta girando indefinidamente. Ese era el síntoma de "no carga nunca".
const Duration httpTimeout = Duration(seconds: 10);

/// Esperas antes de cada reintento.
///
/// Los cortes que se ven en el logcat del dispositivo duran segundos, no
/// minutos, y alternan con ventanas buenas. Dos reintentos cortos convierten
/// la mayoría de esos fallos en un éxito sin que el usuario toque nada.
const List<Duration> _backoff = [Duration(seconds: 2), Duration(seconds: 5)];

/// GET con timeout y reintentos ante fallos de red transitorios.
///
/// Solo reintenta lo que puede mejorar solo: un DNS que no resuelve, un socket
/// que no conecta, un timeout. Un 4xx o un JSON roto no se reintentan porque
/// repetir la petición daría exactamente el mismo resultado.
///
/// Los fallos de red salen como [AppFailure] de tipo [FailureKind.network]
/// para que la UI pueda decir "sin conexión" en lugar de un genérico
/// "no se pudo obtener el clima".
Future<http.Response> getWithRetry(
  Uri uri, {
  required LogTrace trace,
  required String label,
}) async {
  Object? lastError;

  for (var attempt = 0; attempt <= _backoff.length; attempt++) {
    try {
      return await trace.step(
        attempt == 0 ? label : '$label (reintento $attempt)',
        () => http.get(uri).timeout(httpTimeout),
        describe: (r) => 'HTTP ${r.statusCode}, ${r.bodyBytes.length} bytes',
      );
    } catch (error) {
      lastError = error;
      if (!isTransientNetworkError(error) || attempt == _backoff.length) break;
      final wait = _backoff[attempt];
      trace.note('red inestable; reintento en ${wait.inSeconds}s');
      await Future<void>.delayed(wait);
    }
  }

  final error = lastError!;
  if (isTransientNetworkError(error)) {
    throw AppFailure(
      FailureKind.network,
      'Sin conexión estable. Reintenta en un momento.',
      cause: error,
    );
  }
  throw error;
}

/// Un fallo que puede desaparecer solo en cuanto vuelva la señal.
bool isTransientNetworkError(Object error) =>
    error is TimeoutException ||
    error is SocketException ||
    error is HandshakeException ||
    error is http.ClientException;
