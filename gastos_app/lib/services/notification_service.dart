import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones locales:
///  * Alerta inmediata cuando un gasto lleva el presupuesto a >= 80 %.
///  * Recordatorio PROGRAMADO cada domingo a las 20:00 para revisar la semana.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'presupuesto',
      'Alertas de presupuesto',
      channelDescription: 'Avisos cuando te acercas al límite de tu presupuesto',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    // Zona horaria fija para el MVP (cámbiala si tu región es otra).
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> alertaPresupuesto({
    required String presupuestoId,
    required String categoria,
    required double porcentaje,
    required String periodo,
  }) {
    final superado = porcentaje >= 100;
    final pct = porcentaje.toStringAsFixed(0);
    return _plugin.show(
      presupuestoId.hashCode & 0x7fffffff,
      superado ? 'Presupuesto superado' : 'Estás cerca de tu límite',
      superado
          ? 'Superaste tu presupuesto $periodo de $categoria ($pct %).'
          : 'Has usado el $pct % de tu presupuesto $periodo de $categoria.',
      _detalles,
    );
  }

  /// Programa (o reprograma) el recordatorio semanal repetitivo.
  Future<void> programarRecordatorioSemanal() async {
    await _plugin.zonedSchedule(
      1001,
      'Revisa tus gastos',
      'Es domingo: echa un vistazo a cómo te fue esta semana.',
      _proximoDomingo20h(),
      _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _proximoDomingo20h() {
    final ahora = tz.TZDateTime.now(tz.local);
    var fecha = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, 20);
    while (fecha.weekday != DateTime.sunday || fecha.isBefore(ahora)) {
      fecha = fecha.add(const Duration(days: 1));
    }
    return fecha;
  }
}
