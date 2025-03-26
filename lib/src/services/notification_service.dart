import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugin with categories and response handling.
  Future<void> initialize(Function(String) onActionSelected) async {
    tz.initializeTimeZones();

    // Android initialization settings
    final androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings with notification categories
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'HOURLY_CHECKIN',
          actions: [
            DarwinNotificationAction.plain('productive', 'Productive'),
            DarwinNotificationAction.plain('unproductive', 'Unproductive'),
          ],
          options: {
            DarwinNotificationCategoryOption.customDismissAction,
            DarwinNotificationCategoryOption.allowInCarPlay,
          },
        ),
      ],
    );

    // Combine settings for both platforms
    final initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize the plugin with response handling
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId != null) {
          onActionSelected(response.actionId!);
        }
      },
    );
  }

  /// Schedules notifications every minute for testing purposes.
  Future<void> scheduleHourlyNotifications() async {
    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'hourly_focus',
      'Hourly Check-In',
      channelDescription: 'Prompts for productivity tracking',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('productive', 'Productive'),
        AndroidNotificationAction('unproductive', 'Unproductive'),
      ],
    );

    // iOS notification details linked to the category
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'HOURLY_CHECKIN',
    );

    // Combine details for both platforms
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // New code for testing: Schedule notifications every minute for the next 5 minutes
    final now = DateTime.now();
    for (int minute = 1; minute <= 5; minute++) {
      final scheduledTime = tz.TZDateTime.from(
        now.add(Duration(minutes: minute)),
        tz.local,
      );
      await _plugin.zonedSchedule(
        minute,
        'How was this minute?',
        'Mark it as Productive or Unproductive',
        scheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: minute.toString(),
      );
    }

    // Original hourly scheduling code (commented out to keep it unaffected)
    /*
    final now = DateTime.now();
    for (int hour = 8; hour <= 22; hour++) {
      final scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (scheduledTime.isAfter(now)) {
        await _plugin.zonedSchedule(
          hour,
          'How was this hour?',
          'Mark it as Productive or Unproductive',
          scheduledTime,
          notificationDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: hour.toString(),
        );
      }
    }
    */
  }
}
