import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class Notifications {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
    // TZ init for zoned scheduling
    try { tzdata.initializeTimeZones(); } catch (_) {}
  }

  static Future<void> showRestComplete() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest-timers',
      'Rest Timers',
      channelDescription: 'Alerts when rest timers complete',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(1001, 'Rest complete', 'Time to go!', details);
  }

  static Future<void> scheduleRestCompleteAt(DateTime whenLocal, {int id = 2001}) async {
    final tz.TZDateTime tzWhen = tz.TZDateTime.from(whenLocal, tz.local);
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rest-timers',
      'Rest Timers',
      channelDescription: 'Alerts when rest timers complete',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.zonedSchedule(
      id,
      'Rest complete',
      'Time to go!',
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: 'rest-complete',
    );
  }

  static Future<void> cancelScheduledRest({int id = 2001}) async {
    await _plugin.cancel(id);
  }
}


