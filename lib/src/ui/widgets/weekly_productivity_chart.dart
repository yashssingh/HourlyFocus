import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class WeeklyProductivityChart extends StatelessWidget {
  final List<LogEntry> logs;

  const WeeklyProductivityChart({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekData = _prepareWeeklyData(now);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            
            SizedBox(
              height: 160,
              child: WeeklyChart(
                weekData: weekData,
                today: now,
                theme: theme,
              ),
            ),
            
            SizedBox(height: 12),
            
            // Legend
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(
                    Colors.green.shade500, 
                    'Productive', 
                    theme
                  ),
                  SizedBox(width: 24),
                  _buildLegendItem(
                    Colors.red.shade400, 
                    'Unproductive', 
                    theme
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<DayData> _prepareWeeklyData(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    
    return List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        return logDate.isAtSameMomentAs(date);
      }).toList();
      
      // Filter out BOT entries when counting productive hours
      final productive = dayLogs.where((log) => 
        log.status == 'productive' && !log.note.toUpperCase().contains('BOT')
      ).length;
      
      final unproductive = dayLogs.where((log) => 
        log.status == 'unproductive' || log.note.toUpperCase().contains('BOT')
      ).length;
      
      return DayData(
        date: date,
        productive: productive,
        unproductive: unproductive,
      );
    });
  }
  
  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class WeeklyChart extends StatelessWidget {
  final List<DayData> weekData;
  final DateTime today;
  final ThemeData theme;
  
  const WeeklyChart({
    Key? key,
    required this.weekData,
    required this.today,
    required this.theme,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Find max value for scaling
    int maxValue = 0;
    for (var data in weekData) {
      final total = data.productive + data.unproductive;
      if (total > maxValue) maxValue = total;
    }
    
    // Set reasonable min/max values
    maxValue = maxValue > 0 ? maxValue : 8;
    maxValue = maxValue > 24 ? 24 : maxValue;
    
    // Round up to nearest multiple of 4 for nice y-axis divisions
    maxValue = ((maxValue + 3) ~/ 4) * 4;
    
    final isDark = theme.brightness == Brightness.dark;
    final gridColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    
    return Container(
      constraints: BoxConstraints(maxHeight: 160),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth / 20;
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: WeeklyChartPainter(
                weekData: weekData,
                maxValue: maxValue,
                today: today,
                gridColor: gridColor,
                textColor: textColor,
                productiveColor: Colors.green.shade500,
                unproductiveColor: Colors.red.shade400,
                barWidth: barWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

class WeeklyChartPainter extends CustomPainter {
  final List<DayData> weekData;
  final int maxValue;
  final DateTime today;
  final Color gridColor;
  final Color textColor;
  final Color productiveColor;
  final Color unproductiveColor;
  final double barWidth;
  
  WeeklyChartPainter({
    required this.weekData,
    required this.maxValue,
    required this.today,
    required this.gridColor,
    required this.textColor,
    required this.productiveColor,
    required this.unproductiveColor,
    required this.barWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width;
    final chartHeight = size.height - 20; // Reserve less space for x-axis labels
    final leftPadding = 24.0;  // Less space for y-axis labels
    
    final availableWidth = chartWidth - leftPadding;
    final barSpacing = availableWidth / 7;
    
    // Draw y-axis grid lines and labels
    final yAxisPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5 // Thinner lines
      ..style = PaintingStyle.stroke;
    
    final yAxisTextStyle = TextStyle(
      color: textColor,
      fontSize: 9, // Smaller font
    );
    
    // Draw fewer grid lines (4 instead of 6)
    final yStep = chartHeight / 4;
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (i * yStep);
      
      // Draw grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(chartWidth, y),
        yAxisPaint,
      );
      
      // Draw y-axis label
      if (i % 2 == 0) { // Only show labels for every other line
        final value = (i * maxValue / 4).round();
        final textSpan = TextSpan(
          text: value.toString(),
          style: yAxisTextStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(leftPadding - textPainter.width - 2, y - (textPainter.height / 2)),
        );
      }
    }
    
    // Draw bars and x-axis labels
    for (int i = 0; i < weekData.length; i++) {
      final data = weekData[i];
      final centerX = leftPadding + (i * barSpacing) + (barSpacing / 2);
      
      // Draw productive bar
      if (data.productive > 0) {
        final height = (data.productive / maxValue) * chartHeight;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            centerX - barWidth - 1, // Less spacing
            chartHeight - height,
            barWidth,
            height,
          ),
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        );
        
        canvas.drawRRect(
          rect,
          Paint()..color = productiveColor,
        );
      }
      
      // Draw unproductive bar
      if (data.unproductive > 0) {
        final height = (data.unproductive / maxValue) * chartHeight;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            centerX + 1, // Less spacing
            chartHeight - height,
            barWidth,
            height,
          ),
          topLeft: Radius.circular(3),
          topRight: Radius.circular(3),
        );
        
        canvas.drawRRect(
          rect,
          Paint()..color = unproductiveColor,
        );
      }
      
      // Draw x-axis day label
      final isToday = _isToday(data.date, today);
      final textStyle = TextStyle(
        color: isToday ? productiveColor : textColor,
        fontSize: 9, // Smaller font
        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
      );
      
      final dayText = TextSpan(
        text: DateFormat('EEE').format(data.date),
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: dayText,
        textDirection: ui.TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(centerX - (textPainter.width / 2), chartHeight + 4), // Less spacing
      );
    }
  }
  
  bool _isToday(DateTime date, DateTime today) {
    return date.year == today.year && 
           date.month == today.month &&
           date.day == today.day;
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DayData {
  final DateTime date;
  final int productive;
  final int unproductive;
  
  DayData({
    required this.date,
    required this.productive,
    required this.unproductive,
  });
} 