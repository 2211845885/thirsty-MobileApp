import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
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
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // handle tap if needed
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _notifications.show(
          0,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'hydration_channel',
              'Hydration Reminders',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification tapped: ${message.notification?.title}");
    });

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          "App launched from notification: ${initialMessage.notification?.title}");
    }
  }

  static Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<void> scheduleRepeating({
    required int id,
    required String title,
    required String body,
    required Duration interval,
  }) async {
    await cancel(id);
    final now = tz.TZDateTime.now(tz.local);
    final next = now.add(interval);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      time,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  static Future<void> getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $token');
  }
}
