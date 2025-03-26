import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:intl/intl.dart';

class DailySummaryCard extends StatelessWidget {
  final List<LogEntry> logs;
  final DateTime date;

  const DailySummaryCard({
    Key? key,
    required this.logs,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayLogs = logs.where((log) {
      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      final selectedDate = DateTime(date.year, date.month, date.day);
      return logDate.isAtSameMomentAs(selectedDate);
    }).toList();
    
    final productiveCount = todayLogs.where((log) => log.status == 'productive').length;
    final totalLogs = todayLogs.length;
    final double productivityRate = totalLogs > 0 
        ? (productiveCount / totalLogs) * 100 
        : 0;
        
    final String formattedDate = DateFormat('EEE, MMM d').format(date);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  return Row(
                    children: [
                      if (totalLogs > 0)
                        Container(
                          height: 8,
                          width: availableWidth * (productiveCount / totalLogs),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ),
            
            SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$productiveCount/$totalLogs',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Productive hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreBackgroundColor(productivityRate),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${productivityRate.toInt()}%',
                    style: TextStyle(
                      color: _getScoreTextColor(productivityRate),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getScoreBackgroundColor(double score) {
    if (score >= 70) return Colors.green.withOpacity(0.2);
    if (score >= 40) return Colors.amber.withOpacity(0.2);
    return Colors.red.withOpacity(0.2);
  }
  
  Color _getScoreTextColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.amber.shade800;
    return Colors.red;
  }
} 