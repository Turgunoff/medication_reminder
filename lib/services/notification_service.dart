import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleMedicationReminder(Medication medication) async {
    try {
      final times = _parseTimes(medication.times);

      for (int i = 0; i < times.length; i++) {
        final time = times[i];
        final now = DateTime.now();
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If time has passed today, schedule for tomorrow
        final targetTime = scheduledTime.isBefore(now)
            ? scheduledTime.add(const Duration(days: 1))
            : scheduledTime;

        // Schedule notification 10 minutes before
        final notificationTime = targetTime.subtract(
          const Duration(minutes: 10),
        );

        // Only schedule if notification time is in the future
        if (notificationTime.isAfter(now)) {
          await _notifications.zonedSchedule(
            _getNotificationId(medication.id!, i),
            '💊 Dori ichish vaqti yaqinlashmoqda!',
            '${medication.name} ni 10 daqiqadan so\'ng iching',
            tz.TZDateTime.from(notificationTime, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'medication_reminders',
                'Dori eslatmalari',
                channelDescription: 'Dori ichish vaqtini eslatish',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                enableLights: true,
                color: Color(0xFF2196F3),
                icon: '@mipmap/ic_launcher',
                channelShowBadge: true,
                onlyAlertOnce: false,
                autoCancel: false,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                badgeNumber: 1,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: jsonEncode({
              'medicationId': medication.id,
              'medicationName': medication.name,
              'timeIndex': i,
              'time': notificationTime.toString(),
            }),
          );

          print(
            '✅ Notification scheduled for ${medication.name} at ${notificationTime.toString()}',
          );
        } else {
          print(
            '⚠️ Skipping notification for ${medication.name} - time has passed',
          );
        }
      }
    } catch (e) {
      print('❌ Error scheduling notification for ${medication.name}: $e');
    }
  }

  Future<void> cancelMedicationReminders(int medicationId) async {
    try {
      final times = [1, 2, 3, 4, 5]; // Maximum 5 times per medication
      for (int i = 0; i < times.length; i++) {
        await _notifications.cancel(_getNotificationId(medicationId, i));
      }
      print('✅ Cancelled notifications for medication ID: $medicationId');
    } catch (e) {
      print(
        '❌ Error cancelling notifications for medication ID $medicationId: $e',
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ Cancelled all notifications');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  int _getNotificationId(int medicationId, int timeIndex) {
    return medicationId * 100 + timeIndex;
  }

  List<TimeOfDay> _parseTimes(String timesJson) {
    try {
      final List<dynamic> timesList = jsonDecode(timesJson);
      return timesList.map((timeMap) {
        return TimeOfDay(hour: timeMap['hour'], minute: timeMap['minute']);
      }).toList();
    } catch (e) {
      print('❌ Error parsing times JSON: $e');
      return [];
    }
  }

  Future<void> requestPermissions() async {
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      print('✅ Notification permissions requested');
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }

  // Test notification for debugging
  Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        999,
        '🧪 Test Notification',
        'Bu test notification',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error showing test notification: $e');
    }
  }

  // Get pending (scheduled) notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }
}
