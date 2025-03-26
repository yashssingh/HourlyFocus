import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hourly_focus/src/services/notification_service.dart';
import 'package:hourly_focus/src/ui/screens/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final NotificationService notificationService;

  const SplashScreen({Key? key, required this.notificationService}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToDashboard();
  }

  _navigateToDashboard() async {
    // Wait 2 seconds before navigating to the dashboard
    await Future.delayed(Duration(seconds: 2));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          notificationService: widget.notificationService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo image
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            ).animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: Offset(0.8, 0.8)),
              
            SizedBox(height: 24),
            
            // App name text
            Text(
              'HourlyFocus',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ).animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0),
              
            SizedBox(height: 8),
            
            // Tagline
            Text(
              'Track your productivity, one hour at a time',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ).animate()
              .fadeIn(duration: 600.ms, delay: 500.ms),
              
            SizedBox(height: 48),
            
            // Loading indicator
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ).animate()
              .fadeIn(duration: 600.ms, delay: 800.ms),
          ],
        ),
      ),
    );
  }
} 