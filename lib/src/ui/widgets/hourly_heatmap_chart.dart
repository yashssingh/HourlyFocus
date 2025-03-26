import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';

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
      if (log.status == 'productive') {
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
    
    // Find max total logs in any hour for normalization
    int maxTotalLogs = 0;
    totalHours.forEach((hour, count) {
      if (count > maxTotalLogs) maxTotalLogs = count;
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Most Productive Hours',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildTimeLabels(context),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeatmap(
                    context: context,
                    productivityRates: productivityRates,
                    totalHours: totalHours,
                    maxTotalLogs: maxTotalLogs,
                  ),
                  SizedBox(height: 4),
                  _buildLegend(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTimeLabels(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'AM',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 37),
        Text(
          'PM',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeatmap({
    required BuildContext context,
    required Map<int, double> productivityRates,
    required Map<int, int> totalHours,
    required int maxTotalLogs,
  }) {
    return Container(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(24, (hour) {
          final productivityRate = productivityRates[hour] ?? 0.0;
          final totalLogsForHour = totalHours[hour] ?? 0;
          
          // Determine cell size based on total logs (minimum size applied)
          final double cellHeight = totalLogsForHour > 0
              ? 30.0 + (totalLogsForHour / maxTotalLogs) * 50.0
              : 25.0;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: _getHourLabel(hour) + 
                    '\nProductive: ${(productivityRate * 100).toInt()}%' +
                    '\nEntries: $totalLogsForHour',
                textStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
                child: Container(
                  width: 10,
                  height: cellHeight,
                  decoration: BoxDecoration(
                    color: _getProductivityColor(productivityRate, totalLogsForHour > 0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (hour % 3 == 0) 
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    hour.toString(),
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
  
  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Low', _getProductivityColor(0.2, true), context),
        SizedBox(width: 8),
        _buildLegendItem('Medium', _getProductivityColor(0.5, true), context),
        SizedBox(width: 8),
        _buildLegendItem('High', _getProductivityColor(0.8, true), context),
        SizedBox(width: 8),
        _buildLegendItem('No Data', _getProductivityColor(0, false), context),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
  
  Color _getProductivityColor(double rate, bool hasData) {
    if (!hasData) return Colors.grey.shade200;
    if (rate >= 0.7) return Colors.green.shade700;
    if (rate >= 0.5) return Colors.green;
    if (rate >= 0.3) return Colors.amber;
    return Colors.red;
  }
  
  String _getHourLabel(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }
} 