import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:intl/intl.dart';

class ProductivityLineChart extends StatelessWidget {
  final List<LogEntry> logs;

  const ProductivityLineChart({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort logs by timestamp
    final sortedLogs = List<LogEntry>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sortedLogs.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timeline_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text(
                'No logs available for today',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Process data points for the chart
    final productiveSpots = <FlSpot>[];
    final unproductiveSpots = <FlSpot>[];

    // Track cumulative counts for the running total
    int cumulativeProductive = 0;
    int cumulativeUnproductive = 0;

    for (int i = 0; i < sortedLogs.length; i++) {
      final log = sortedLogs[i];
      final hour = log.timestamp.hour + (log.timestamp.minute / 60);

      if (log.status == 'productive') {
        cumulativeProductive++;
      } else {
        cumulativeUnproductive++;
      }

      final xValue = hour.toDouble();
      final yValueProductive = cumulativeProductive.toDouble();
      final yValueUnproductive = cumulativeUnproductive.toDouble();

      productiveSpots.add(FlSpot(xValue, yValueProductive));
      unproductiveSpots.add(FlSpot(xValue, yValueUnproductive));
    }

    final maxY = (cumulativeProductive + cumulativeUnproductive).toDouble();

    // Calculate earliest and latest times in the logs to set the x-axis range
    final earliestTime = sortedLogs.first.timestamp;
    final latestTime = sortedLogs.last.timestamp;
    final startHour = earliestTime.hour - 1 < 0 ? 0 : earliestTime.hour - 1;
    final endHour = latestTime.hour + 1 > 23 ? 23 : latestTime.hour + 1;

    return Container(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: logs.isNotEmpty
            ? AspectRatio(
                aspectRatio: 1.7,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.shade800,
                        tooltipRoundedRadius: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final flSpot = barSpot;
                            final time = DateTime(2022, 1, 1, flSpot.x.toInt(),
                                ((flSpot.x % 1) * 60).toInt());

                            return LineTooltipItem(
                              '${DateFormat('h:mm a').format(time)}\n',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${flSpot.y.toInt()} entries',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      drawVerticalLine: true,
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      verticalInterval: 6,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final hour = value.toInt();
                            if (hour % 4 != 0) return SizedBox();

                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('h a')
                                    .format(DateTime(2022, 1, 1, hour)),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
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
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value.toInt() != value) {
                              return SizedBox();
                            }
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    minX: startHour.toDouble(),
                    maxX: endHour.toDouble(),
                    minY: 0,
                    maxY: maxY + 1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: productiveSpots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.green,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.15),
                        ),
                      ),
                      LineChartBarData(
                        spots: unproductiveSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.red,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Center(
                child: Text(
                  'No logs available for today',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }
}
