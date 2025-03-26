import 'package:flutter/material.dart';
import 'package:hourly_focus/app.dart';
import 'package:hourly_focus/src/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hourly_focus/src/services/database_service.dart';
import 'package:hourly_focus/src/models/log_entry.dart';

// This is required to be a top-level function for background handlers
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Handle the notification action response here
  if (response.actionId == 'productive' || response.actionId == 'unproductive') {
    // Create a database service
    final dbService = DatabaseService();
    
    // Log the response
    dbService.insertLog(LogEntry(
      timestamp: DateTime.now(),
      status: response.actionId!,
      note: 'Logged from lockscreen',
    ));
    
    print('Background notification action: ${response.actionId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Required for notifications
  
  final notificationService = NotificationService();
  await notificationService.initialize((action) async {
    // Handle foreground notification actions
    if (action == 'productive' || action == 'unproductive') {
      final dbService = DatabaseService();
      await dbService.insertLog(LogEntry(
        timestamp: DateTime.now(),
        status: action,
        note: 'Logged from notification',
      ));
      print('Foreground action logged: $action');
    }
  });
  
  // Check if app was launched from a notification action
  final notificationAppLaunchDetails = 
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp == true &&
      notificationAppLaunchDetails?.notificationResponse?.actionId != null) {
    final action = notificationAppLaunchDetails!.notificationResponse!.actionId!;
    if (action == 'productive' || action == 'unproductive') {
      final dbService = DatabaseService();
      await dbService.insertLog(LogEntry(
        timestamp: DateTime.now(),
        status: action,
        note: 'Logged from app launch',
      ));
      print('App launch action logged: $action');
    }
  }
  
  runApp(HourlyFocusApp(notificationService: notificationService));
}
