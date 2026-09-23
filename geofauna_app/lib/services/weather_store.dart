import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'app_log.dart';
import 'location_service.dart';
import 'marine_service.dart';
import 'weather_service.dart';

const _log = AppLog('STORE');

/// Cuánto vale un pronóstico antes de volver a pedirlo.
const Duration _freshFor = Duration(minutes: 15);

/// Ubicación + clima + marino ya resueltos, con la marca de cuándo se
/// obtuvieron y de si salieron de la red o del disco.
class WeatherData {
  const WeatherData({
    required this.location,
    required this.forecast,
    required this.marineForecast,
    required this.fetchedAt,
    required this.fromCache,
  });

  final UserLocation location;
  final WeatherForecast forecast;
  final MarineForecast? marineForecast;

  /// Cuándo se pidió a Open-Meteo. Con [fromCache] es la hora en que se guardó.
  final DateTime fetchedAt;

  /// Viene del disco porque la red falló: es el último dato bueno, no el de
  /// ahora. La tarjeta lo etiqueta para que nadie los confunda.
  final bool fromCache;

  CurrentWeather get weather => forecast.current;

  /// Antigüedad legible, o `null` cuando el dato es de esta misma carga: no
  /// hay que ensuciar la tarjeta con una etiqueta que no aporta nada.
  String? get ageLabel {
    if (!fromCache) return null;
    final minutes = DateTime.now().difference(fetchedAt).inMinutes;
    if (minutes < 1) return 'hace un momento';
    if (minutes < 60) return 'hace $minutes min';
    final hours = minutes ~/ 60;
    if (hours < 24) return 'hace $hours h';
    return 'hace ${hours ~/ 24} d';
  }
}

/// Fuente única de ubicación y clima para toda la app.
///
/// Sustituye al `static Future` que guardaba cada `WeatherBuilder`, que tenía
/// tres problemas: cacheaba los fallos para siempre (un corte de red en el
/// arranque dejaba la tarjeta rota hasta reiniciar), no se refrescaba nunca
/// aunque la app pasara horas abierta, y cada pantalla guardaba su propia
/// copia, así que "Reintentar" en el Dashboard no arreglaba la Agenda.
///
/// Además publica la ubicación en cuanto la tiene, sin esperar al clima, para
/// que el mapa pueda centrarse aunque Open-Meteo no conteste.
class WeatherStore extends ChangeNotifier {
  WeatherStore._() {
    _watchConnectivity();
  }

  /// Instancia única: vive lo que vive la app y no se hace `dispose`.
  static final WeatherStore instance = WeatherStore._();

  UserLocation? _location;
  Object? _locationError;
  WeatherData? _data;
  Object? _error;
  DateTime? _loadedAt;
  Future<void>? _inFlight;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Ubicación ya resuelta, aunque el clima siga cargando o haya fallado.
  UserLocation? get location => _location;

  /// Estado del clima para las tarjetas. Se expone como [AsyncSnapshot] porque
  /// es justo lo que ya consumían Dashboard y Agenda cuando cada una tenía su
  /// propio `FutureBuilder`.
  AsyncSnapshot<WeatherData> get snapshot {
    final data = _data;
    if (data != null) return AsyncSnapshot.withData(ConnectionState.done, data);
    final error = _error ?? _locationError;
    if (error != null) {
      return AsyncSnapshot.withError(ConnectionState.done, error);
    }
    return const AsyncSnapshot<WeatherData>.waiting();
  }

  /// Estado de la ubicación a secas, para el mapa: no necesita el clima y no
  /// debería quedarse en blanco solo porque Open-Meteo no responda.
  AsyncSnapshot<UserLocation> get locationSnapshot {
    final location = _location;
    if (location != null) {
      return AsyncSnapshot.withData(ConnectionState.done, location);
    }
    final error = _locationError;
    if (error != null) {
      return AsyncSnapshot.withError(ConnectionState.done, error);
    }
    return const AsyncSnapshot<UserLocation>.waiting();
  }

  bool get _isFresh {
    final loadedAt = _loadedAt;
    return _data != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _freshFor;
  }

  /// Carga si hace falta. Varias pantallas montándose a la vez comparten una
  /// sola petición, en lugar de disparar cada una su propio GPS y su propio
  /// geocoding como pasaba antes.
  ///
  /// No notifica de forma síncrona a propósito: se la llama desde `initState`,
  /// y tocar el árbol mientras se está construyendo es un error en Flutter.
  Future<void> ensureLoaded({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (!force && _isFresh) return Future<void>.value();

    final future = _load();
    _inFlight = future;
    return future;
  }

  /// Reintento explícito del usuario, desde cualquier pantalla. Al vivir el
  /// estado en un solo sitio, arregla todas las tarjetas a la vez.
  void refresh() {
    _log.info('el usuario pidió recargar');
    _error = null;
    _locationError = null;
    _loadedAt = null;
    unawaited(ensureLoaded(force: true));
    notifyListeners();
  }

  /// Reintenta solo en cuanto vuelve la red.
  ///
  /// Los cortes que se ven en el logcat duran segundos y alternan con ventanas
  /// buenas. Esperar a que el usuario se dé cuenta y pulse "Reintentar" es
  /// peor que reaccionar al evento que el sistema ya nos está dando.
  void _watchConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;
      if (_error == null && _locationError == null && _isFresh) return;
      _log.info('volvió la red; recargando');
      unawaited(ensureLoaded(force: true));
    });
  }

  Future<void> _load() async {
    final trace = _log.trace('cargar ubicación + clima');
    try {
      final location = await trace.step(
        'ubicación',
        LocationService().getCurrentLocation,
        describe: (l) => '${l.title} (${l.latitude}, ${l.longitude})',
      );
      _location = location;
      _locationError = null;
      // El mapa ya puede centrarse aunque el clima tarde o no llegue nunca.
      notifyListeners();

      await _loadWeather(location, trace);
      trace.done();
    } catch (error) {
      // Solo llega aquí un fallo de ubicación: sin coordenadas no hay clima
      // que pedir. `_loadWeather` resuelve los suyos por dentro.
      trace.failed(error);
      _locationError = error;
      // Lo que ya se veía se conserva: perderlo por un reintento fallido es
      // justo lo que este cambio venía a evitar. El error solo llega a la
      // pantalla cuando no hay absolutamente nada que enseñar.
      if (_data == null) _error = error;
      _loadedAt = null;
    } finally {
      _inFlight = null;
      notifyListeners();
    }
  }

  /// Pide clima y marino, y si la red falla recurre al disco. No relanza:
  /// deja el estado listo para que la UI lo pinte.
  Future<void> _loadWeather(UserLocation location, LogTrace trace) async {
    final weather = WeatherService();
    final marine = MarineService();

    // Las dos peticiones arrancan a la vez: son servidores distintos y
    // ninguna depende de la otra.
    final marineFuture = _marine(marine, location, trace);

    Object? weatherError;
    try {
      final forecast = await trace.step(
        'clima',
        () => weather.fetchForecast(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
      final marineForecast = await trace.step(
        'marino',
        () => marineFuture,
        describe: (m) => m == null ? 'omitido' : '${m.hourly.length} horas',
      );
      _data = WeatherData(
        location: location,
        forecast: forecast,
        marineForecast: marineForecast,
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
      _error = null;
      _loadedAt = DateTime.now();
      return;
    } catch (error) {
      weatherError = error;
      trace.note('clima no disponible; se busca el último guardado');
    }

    final cached = await weather.cachedForecast(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (cached != null) {
      _data = WeatherData(
        location: location,
        forecast: cached.forecast,
        marineForecast: await marineFuture,
        fetchedAt: cached.savedAt,
        fromCache: true,
      );
      _error = null;
      // Sin `_loadedAt`: un dato de disco no cuenta como carga fresca, así que
      // el siguiente intento vuelve a la red en vez de esperar al TTL.
      _loadedAt = null;
      trace.note('mostrando el clima guardado de ${cached.savedAt}');
      return;
    }

    final previous = _data;
    if (previous != null) {
      // Se conserva el pronóstico anterior, pero marcado: ya no es de ahora y
      // la tarjeta debe decirlo.
      _data = WeatherData(
        location: previous.location,
        forecast: previous.forecast,
        marineForecast: previous.marineForecast,
        fetchedAt: previous.fetchedAt,
        fromCache: true,
      );
      _loadedAt = null;
      return;
    }

    _error = weatherError;
    _loadedAt = null;
  }

  /// El marino es opcional: ni su fallo ni su ausencia pueden tumbar la
  /// tarjeta, así que nunca lanza.
  Future<MarineForecast?> _marine(
    MarineService service,
    UserLocation location,
    LogTrace trace,
  ) async {
    try {
      return await service.fetchForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (error) {
      trace.note('marino no disponible ($error); se busca en caché');
    }
    try {
      return await service.cachedForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (error) {
      trace.note('caché marino no disponible ($error); se sigue sin oleaje');
      return null;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
