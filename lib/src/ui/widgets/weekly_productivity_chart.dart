import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:intl/intl.dart';

class WeeklyProductivityChart extends StatelessWidget {
  final List<LogEntry> logs;

  const WeeklyProductivityChart({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final weeklyData = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        return logDate.isAtSameMomentAs(date);
      }).toList();

      final productiveCount = dayLogs.where((log) => log.status == 'productive').length;
      final unproductiveCount = dayLogs.where((log) => log.status == 'unproductive').length;

      return _DayProductivity(
        day: date,
        productiveCount: productiveCount,
        unproductiveCount: unproductiveCount,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your weekly performance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayData = weeklyData[group.x.toInt()];
                    final isProductiveRod = rodIndex == 0;
                    final count = isProductiveRod
                        ? dayData.productiveCount
                        : dayData.unproductiveCount;
                    final label = isProductiveRod ? 'Productive' : 'Unproductive';
                    
                    return BarTooltipItem(
                      '$label: $count hrs\n',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: DateFormat('E, MMM d').format(dayData.day),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final weekday = DateFormat('E').format(weeklyData[value.toInt()].day);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          weekday,
                          style: TextStyle(
                            color: _isToday(weeklyData[value.toInt()].day)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade600,
                            fontWeight: _isToday(weeklyData[value.toInt()].day)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 20,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: weeklyData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                
                return BarChartGroupData(
                  x: index,
                  groupVertically: false,
                  barRods: [
                    BarChartRodData(
                      toY: data.productiveCount.toDouble(),
                      color: Colors.green,
                      width: 12,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(0, data.productiveCount.toDouble(), Colors.green),
                      ],
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 8, // Maximum expected hours per day
                        color: Colors.grey.shade200,
                      ),
                    ),
                    BarChartRodData(
                      toY: data.unproductiveCount.toDouble(),
                      color: Colors.red,
                      width: 12,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(0, data.unproductiveCount.toDouble(), Colors.red),
                      ],
                    ),
                  ],
                );
              }).toList(),
              maxY: 8, // Maximum expected hours per day
            ),
            swapAnimationDuration: Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Productive', Colors.green, context),
            SizedBox(width: 16),
            _buildLegendItem('Unproductive', Colors.red, context),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade700
                : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _DayProductivity {
  final DateTime day;
  final int productiveCount;
  final int unproductiveCount;

  _DayProductivity({
    required this.day,
    required this.productiveCount,
    required this.unproductiveCount,
  });
} 