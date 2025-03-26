import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:intl/intl.dart';

class HourlyHeatmapChart extends StatelessWidget {
  final List<LogEntry> logs;

  const HourlyHeatmapChart({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Count productive hours by hour of day
    final Map<int, int> productiveHours = {};
    final Map<int, int> totalHours = {};
    
    // Initialize maps with zeros for all hours
    for (int hour = 0; hour < 24; hour++) {
      productiveHours[hour] = 0;
      totalHours[hour] = 0;
    }
    
    // Populate hourly data from logs
    for (final log in logs) {
      final hour = log.timestamp.hour;
      totalHours[hour] = (totalHours[hour] ?? 0) + 1;
      
      // Check if the note contains "BOT" text which indicates overflow
      bool isBot = log.note.toUpperCase().contains("BOT");
      
      if (log.status == 'productive' && !isBot) {
        productiveHours[hour] = (productiveHours[hour] ?? 0) + 1;
      }
    }
    
    // Calculate productivity rates for each hour
    final Map<int, double> productivityRates = {};
    for (int hour = 0; hour < 24; hour++) {
      if (totalHours[hour]! > 0) {
        productivityRates[hour] = productiveHours[hour]! / totalHours[hour]!;
      } else {
        productivityRates[hour] = 0.0;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
          child: Text(
            'Most Productive Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // AM hours (0-11)
        _buildHourSection('AM', 0, 11, productivityRates, totalHours),
        
        SizedBox(height: 16),
        
        // PM hours (12-23)
        _buildHourSection('PM', 12, 23, productivityRates, totalHours),
        
        // Legend
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green.shade200, 'Low'),
              SizedBox(width: 16),
              _buildLegendItem(Colors.green.shade500, 'Medium'),
              SizedBox(width: 16),
              _buildLegendItem(Colors.green.shade800, 'High'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHourSection(String label, int startHour, int endHour, 
                          Map<int, double> productivityRates, Map<int, int> totalHours) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label (AM/PM)
        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700
              ),
            ),
          ),
        ),
        
        // Hours
        Expanded(
          child: SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              itemCount: endHour - startHour + 1,
              itemBuilder: (context, index) {
                final hour = startHour + index;
                final productivityRate = productivityRates[hour] ?? 0.0;
                final totalLogsForHour = totalHours[hour] ?? 0;
                
                return SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: '${_getHourLabel(hour)}\nProductive: ${(productivityRate * 100).toInt()}%\nEntries: $totalLogsForHour',
                          child: Container(
                            width: 14,
                            decoration: BoxDecoration(
                              color: _getProductivityColor(productivityRate, totalLogsForHour > 0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        hour.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label, 
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)
        ),
      ],
    );
  }
  
  Color _getProductivityColor(double rate, bool hasData) {
    if (!hasData) return Colors.grey.shade200;
    if (rate >= 0.7) return Colors.green.shade800;
    if (rate >= 0.4) return Colors.green.shade500;
    if (rate > 0) return Colors.green.shade200;
    return Colors.red.shade300;
  }
  
  String _getHourLabel(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }
} 