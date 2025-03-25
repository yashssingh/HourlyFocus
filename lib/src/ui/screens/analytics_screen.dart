import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:hourly_focus/src/services/database_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await _dbService.getLogsForDay(DateTime.now());
    setState(() => _logs = logs);
  }

  List<_PieChartData> _getDailyPieData() {
    final productive = _logs.where((log) => log.status == 'productive').length;
    final unproductive =
        _logs.where((log) => log.status == 'unproductive').length;
    final total = productive + unproductive;
    return total == 0
        ? [_PieChartData('No Data', 1, Colors.grey)]
        : [
            _PieChartData('Productive', productive.toDouble(), Colors.green),
            _PieChartData('Unproductive', unproductive.toDouble(), Colors.red),
          ];
  }

  List<_TrendData> _getWeeklyTrend() {
    // Mock data for a week; replace with actual weekly fetch
    return [
      _TrendData('Mon', 5, 3),
      _TrendData('Tue', 6, 2),
      _TrendData('Wed', 4, 4),
      _TrendData('Thu', 7, 1),
      _TrendData('Fri', 5, 3),
      _TrendData('Sat', 3, 5),
      _TrendData('Sun', 6, 2),
    ];
  }

  List<_HourlyData> _getHourlyDistribution() {
    final Map<int, int> hours = {};
    for (var log in _logs) {
      hours[log.timestamp.hour] = (hours[log.timestamp.hour] ?? 0) +
          (log.status == 'productive' ? 1 : 0);
    }
    return hours.entries
        .map((e) => _HourlyData(e.key, e.value.toDouble()))
        .toList();
  }

  Map<String, int> _getNoteKeywords() {
    final words = _logs.expand((log) => log.note.split(' ')).toList();
    final frequency = <String, int>{};
    for (var word in words) {
      if (word.isNotEmpty) frequency[word] = (frequency[word] ?? 0) + 1;
    }
    return frequency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Productivity',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  PieSeries<_PieChartData, String>(
                    dataSource: _getDailyPieData(),
                    xValueMapper: (_PieChartData data, _) => data.category,
                    yValueMapper: (_PieChartData data, _) => data.value,
                    pointColorMapper: (_PieChartData data, _) => data.color,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Weekly Trend', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<_TrendData, String>(
                    dataSource: _getWeeklyTrend(),
                    xValueMapper: (_TrendData data, _) => data.day,
                    yValueMapper: (_TrendData data, _) => data.productive,
                    name: 'Productive',
                    color: Colors.green,
                  ),
                  ColumnSeries<_TrendData, String>(
                    dataSource: _getWeeklyTrend(),
                    xValueMapper: (_TrendData data, _) => data.day,
                    yValueMapper: (_TrendData data, _) => data.unproductive,
                    name: 'Unproductive',
                    color: Colors.red,
                  ),
                ],
                legend: Legend(isVisible: true),
              ),
            ),
            SizedBox(height: 16),
            Text('Productive Hour Distribution',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(title: AxisTitle(text: 'Hour')),
                series: <CartesianSeries>[
                  BarSeries<_HourlyData, double>(
                    dataSource: _getHourlyDistribution(),
                    xValueMapper: (_HourlyData data, _) => data.hour.toDouble(),
                    yValueMapper: (_HourlyData data, _) => data.count,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Note Keyword Frequency',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<MapEntry<String, int>, String>(
                    dataSource: _getNoteKeywords().entries.toList(),
                    xValueMapper: (MapEntry<String, int> data, _) => data.key,
                    yValueMapper: (MapEntry<String, int> data, _) => data.value,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartData {
  final String category;
  final double value;
  final Color color;
  _PieChartData(this.category, this.value, this.color);
}

class _TrendData {
  final String day;
  final int productive;
  final int unproductive;
  _TrendData(this.day, this.productive, this.unproductive);
}

class _HourlyData {
  final int hour;
  final double count;
  _HourlyData(this.hour, this.count);
}
