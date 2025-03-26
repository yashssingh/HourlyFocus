import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';

class ProductivityScoreCard extends StatelessWidget {
  final List<LogEntry> logs;

  const ProductivityScoreCard({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final productiveCount = logs.where((log) => log.status == 'productive').length;
    final totalLogs = logs.length;
    final double productivityRate = totalLogs > 0 
        ? (productiveCount / totalLogs) * 100 
        : 0;
    
    final Color scoreColor = _getScoreColor(productivityRate);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.1),
                border: Border.all(
                  color: scoreColor,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '${productivityRate.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            
            // Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Productivity Score',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildSimpleStat(
                        label: 'Productive',
                        value: productiveCount,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      _buildSimpleStat(
                        label: 'Unprod.',
                        value: totalLogs - productiveCount,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSimpleStat({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
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
          SizedBox(width: 4),
          Expanded(
            child: Text(
              '$value $label',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.amber;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }
} 