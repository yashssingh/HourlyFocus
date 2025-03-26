import 'package:flutter/material.dart';
import 'package:hourly_focus/src/services/notification_service.dart';
import 'package:hourly_focus/src/ui/screens/home_screen.dart';

class HourlyFocusApp extends StatelessWidget {
  final NotificationService notificationService;

  HourlyFocusApp({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HourlyFocus',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: HomeScreen(notificationService: notificationService),
    );
  }
}
