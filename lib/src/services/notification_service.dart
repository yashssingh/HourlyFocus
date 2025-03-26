import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

// Import main.dart with the background handler
import 'package:hourly_focus/main.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugin with categories and response handling.
  Future<void> initialize(Function(String) onActionSelected) async {
    tz.initializeTimeZones();

    // Android initialization settings with notification channels
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
            DarwinNotificationAction.plain('productive', 'Productive',
                options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain('unproductive', 'Unproductive',
                options: {DarwinNotificationActionOption.foreground}),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request permission for handling notifications when app is terminated
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    // Request additional notification permissions for iOS lock screen
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );
  }

  /// Schedules notifications every minute for testing purposes.
  Future<void> scheduleHourlyNotifications() async {
    // Android notification details with full screen intent for lock screen
    const androidDetails = AndroidNotificationDetails(
      'hourly_focus',
      'Hourly Check-In',
      channelDescription: 'Prompts for productivity tracking',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      actions: [
        AndroidNotificationAction(
          'productive', 
          'Productive',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'unproductive', 
          'Unproductive',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    // iOS notification details linked to the category
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'HOURLY_CHECKIN',
      interruptionLevel: InterruptionLevel.timeSensitive,
      threadIdentifier: 'hourly_focus_thread',
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

// Required for handling notification actions when app is in background or terminated
@pragma('vm:entry-point')
void notificationBackgroundCallback(NotificationResponse response) {
  // This callback will be invoked when the user responds from the lock screen
  // The action ID will be either 'productive' or 'unproductive'
  if (response.actionId != null) {
    // We need to save this response to process when the app is launched
    print('Background action received: ${response.actionId}');
  }
}
