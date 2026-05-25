import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Integra los eventos de GeoFauna con el calendario nativo del teléfono.
///
/// Se usa al publicar un evento (calendario del organizador) y al participar
/// (calendario de quien se une). Guarda el id devuelto por el sistema para
/// poder eliminar el evento del calendario si la persona cancela.
///
/// Todas las operaciones son "best-effort": si el usuario niega el permiso o
/// no hay un calendario donde escribir, devuelven `null`/`false` sin lanzar,
/// para no bloquear el flujo principal de inscripción.
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  bool _tzReady = false;

  Future<void> _ensureTimeZones() async {
    if (_tzReady) return;
    tz_data.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Si no se puede resolver la zona local, timezone usa UTC por defecto.
    }
    _tzReady = true;
  }

  /// Solicita permiso de calendario si hace falta. Devuelve `true` si quedó
  /// concedido.
  Future<bool> ensurePermission() async {
    try {
      var result = await _plugin.hasPermissions();
      if (result.isSuccess && result.data == true) return true;
      result = await _plugin.requestPermissions();
      return result.isSuccess && result.data == true;
    } catch (_) {
      return false;
    }
  }

  /// Agrega un evento al calendario por defecto del teléfono y devuelve el id
  /// del evento creado, o `null` si no fue posible (sin permiso / sin
  /// calendario escribible).
  Future<String?> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    if (!await ensurePermission()) return null;
    await _ensureTimeZones();

    final calendarId = await _writableCalendarId();
    if (calendarId == null) return null;

    final event = Event(
      calendarId,
      title: title,
      start: tz.TZDateTime.from(start, tz.local),
      end: tz.TZDateTime.from(end, tz.local),
      description: description,
      location: location,
    );

    try {
      final result = await _plugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess) return result.data;
    } catch (_) {
      // best-effort
    }
    return null;
  }

  /// Elimina del calendario un evento agregado previamente. No lanza si falla.
  Future<bool> removeEvent(String calendarEventId) async {
    if (!await ensurePermission()) return false;
    final calendarId = await _writableCalendarId();
    if (calendarId == null) return false;
    try {
      final result = await _plugin.deleteEvent(calendarId, calendarEventId);
      return result.isSuccess && result.data == true;
    } catch (_) {
      return false;
    }
  }

  /// Devuelve el id del primer calendario escribible (preferentemente el
  /// marcado como predeterminado), o `null` si no hay ninguno.
  Future<String?> _writableCalendarId() async {
    try {
      final result = await _plugin.retrieveCalendars();
      if (!result.isSuccess || result.data == null) return null;
      final writable = result.data!
          .where((c) => c.isReadOnly == false)
          .toList();
      if (writable.isEmpty) return null;
      final preferred = writable.firstWhere(
        (c) => c.isDefault == true,
        orElse: () => writable.first,
      );
      return preferred.id;
    } catch (_) {
      return null;
    }
  }
}
