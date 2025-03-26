import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hourly_focus/src/models/log_entry.dart';

class MoodDistributionCard extends StatelessWidget {
  final List<LogEntry> logs;

  const MoodDistributionCard({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate distribution
    final productiveCount = logs.where((log) => log.status == 'productive').length;
    final unproductiveCount = logs.where((log) => log.status == 'unproductive').length;
    final totalLogs = productiveCount + unproductiveCount;
    
    final productivePercentage = totalLogs > 0 
        ? (productiveCount / totalLogs) * 100 
        : 0.0;
    final unproductivePercentage = totalLogs > 0 
        ? (unproductiveCount / totalLogs) * 100 
        : 0.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate a safe size that fits within available space
                  return AspectRatio(
                    aspectRatio: 1.6,
                    child: totalLogs > 0
                        ? PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 16,
                              sections: [
                                PieChartSectionData(
                                  value: productivePercentage,
                                  color: Colors.green,
                                  title: '$productiveCount',
                                  titleStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                  radius: 25,
                                  titlePositionPercentageOffset: 0.6,
                                ),
                                PieChartSectionData(
                                  value: unproductivePercentage,
                                  color: Colors.red,
                                  title: '$unproductiveCount',
                                  titleStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                  radius: 25,
                                  titlePositionPercentageOffset: 0.6,
                                ),
                              ],
                              borderData: FlBorderData(show: false),
                            ),
                          )
                        : Center(
                            child: Text(
                              'No data yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  );
                }
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Productive', Colors.green, context),
                  SizedBox(width: 8),
                  _buildLegendItem('Unproductive', Colors.red, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2),
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
} 