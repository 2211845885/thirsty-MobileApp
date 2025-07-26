import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static Timer? _customRepeatingTimer;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tripoli'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android,);
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
    });

  }

  static Future<void> startCustomRepeatingNotification({
  required int id,
  required String title,
  required String body,
  required Duration interval,
}) async {
  stopCustomRepeatingNotification();


  _customRepeatingTimer = Timer.periodic(interval, (_) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  });
}


  static void stopCustomRepeatingNotification() {
    _customRepeatingTimer?.cancel();
    _customRepeatingTimer = null;
  }

  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    stopCustomRepeatingNotification();
  }

}
