import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),

              // Logo
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: Offset(0.9, 0.9)),

              SizedBox(height: 24),

              // App name
              Text(
                'HourlyFocus',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              SizedBox(height: 8),

              // Version
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 300.ms),

              SizedBox(height: 32),

              // Divider
              Divider(thickness: 1),

              SizedBox(height: 24),

              // Description
              Text(
                'HourlyFocus helps you track your productivity hour by hour, providing insights into your daily and weekly performance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

              SizedBox(height: 32),

              // Features list
              _buildFeatureSection(
                context,
                title: 'Key Features',
                features: [
                  'Hour-by-hour productivity tracking',
                  'Detailed productivity analytics',
                  'Daily and weekly performance insights',
                  'Notification reminders',
                  'Data export capabilities',
                ],
              ).animate().fadeIn(duration: 600.ms, delay: 500.ms),

              SizedBox(height: 32),

              // Credits
              _buildCreditsSection(context)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms),

              SizedBox(height: 40),

              // Copyright
              Text(
                '© 2025 HourlyFocus. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 700.ms),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context,
      {required String title, required List<String> features}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 16),
        _buildCreditItem(
          context,
          title: 'Design & Development',
          detail: 'HourlyFocus Team',
        ),
        SizedBox(height: 8),
        _buildCreditItem(
          context,
          title: 'Logo Design',
          detail: 'Meta AI',
        ),
      ],
    );
  }

  Widget _buildCreditItem(BuildContext context,
      {required String title, required String detail}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
