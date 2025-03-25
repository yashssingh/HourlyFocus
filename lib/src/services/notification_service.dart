import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:hourly_focus/src/services/database_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _dbService = DatabaseService();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  Future<void> showLockScreenNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'hourly_focus_lock',
      'Hourly Check-In',
      channelDescription: 'Log hours from lock screen',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('productive', 'Productive',
            showsUserInterface: false),
        AndroidNotificationAction('unproductive', 'Unproductive',
            showsUserInterface: false),
      ],
      visibility:
          NotificationVisibility.public, // Ensures visibility on lock screen
    );
    const iosDetails = DarwinNotificationDetails();
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      0,
      'How was this hour?',
      'Log directly from here!',
      notificationDetails,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'productive') {
      _logHour('productive');
    } else if (response.actionId == 'unproductive') {
      _logHour('unproductive');
    }
  }

  Future<void> _logHour(String status) async {
    final log = LogEntry(
      timestamp: DateTime.now(),
      status: status,
      note: '', // No note from lock screen for simplicity
    );
    await _dbService.insertLog(log);
  }
}
