import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel';

  /// Initialize notifications and timezone support
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Initialize timezone
    tz.initializeTimeZones();
   // final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
   // tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  /// Schedule multiple daily reminders with custom times
  static Future<void> scheduleMultipleReminders(
      List<TimeOfDay> times, String message) async {
    await cancelAllReminders(); // Clear previous

    for (int i = 0; i < times.length; i++) {
      final TimeOfDay t = times[i];
      final scheduledTime = _nextInstanceOfTime(t.hour, t.minute);

      await _notificationsPlugin.zonedSchedule(
        i, // unique ID for each notification
        '💧 Hydration Reminder',
        message,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Hydration Reminders',
            channelDescription: 'Sends daily water drinking reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            // Uncomment below for custom sound (requires sound in res/raw)
            // sound: RawResourceAndroidNotificationSound('custom_sound'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Show immediate notification (for testing)
  static Future<void> showNow(String message) async {
    await _notificationsPlugin.show(
      999, // test notification ID
      '💧 Hydration Reminder',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Hydration Reminders',
          channelDescription: 'Sends immediate hydration alert',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          // sound: RawResourceAndroidNotificationSound('custom_sound'),
        ),
      ),
    );
  }

  /// Helper: get next instance of specific time (today or tomorrow)
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}