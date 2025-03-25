import 'package:flutter/material.dart';
import 'package:hourly_focus/app.dart';
import 'package:hourly_focus/src/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Required for notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService
      .showLockScreenNotification(); // Show notification on app start for testing
  runApp(HourlyFocusApp());
}
