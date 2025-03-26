import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:hourly_focus/src/services/database_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<LogEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _dbService.getLogsForDay(DateTime.now());
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  List<_PieChartData> _getDailyPieData() {
    final productive = _logs.where((log) => log.status == 'productive').length;
    final unproductive =
        _logs.where((log) => log.status == 'unproductive').length;
    final total = productive + unproductive;
    return total == 0
        ? [_PieChartData('No Data', 1, Colors.grey)]
        : [
            _PieChartData('Productive', productive.toDouble(), Color(0xFF4CAF50)),
            _PieChartData('Unproductive', unproductive.toDouble(), Color(0xFFF44336)),
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
      appBar: AppBar(
        title: Text('Analytics'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : AnimationLimiter(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    _buildSectionHeader('Today\'s Productivity'),
                    _buildChartCard(
                      height: 250,
                      child: SfCircularChart(
                        palette: const <Color>[
                          Color(0xFF4CAF50),
                          Color(0xFFF44336),
                          Colors.grey,
                        ],
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                          overflowMode: LegendItemOverflowMode.wrap,
                        ),
                        series: <CircularSeries>[
                          DoughnutSeries<_PieChartData, String>(
                            dataSource: _getDailyPieData(),
                            xValueMapper: (_PieChartData data, _) => data.category,
                            yValueMapper: (_PieChartData data, _) => data.value,
                            pointColorMapper: (_PieChartData data, _) => data.color,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                              textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            enableTooltip: true,
                            animationDuration: 1200,
                            cornerStyle: CornerStyle.bothCurve,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSectionHeader('Weekly Productivity Trend'),
                    _buildChartCard(
                      height: 250,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        palette: const <Color>[
                          Color(0xFF4CAF50),
                          Color(0xFFF44336),
                        ],
                        series: <CartesianSeries>[
                          ColumnSeries<_TrendData, String>(
                            dataSource: _getWeeklyTrend(),
                            xValueMapper: (_TrendData data, _) => data.day,
                            yValueMapper: (_TrendData data, _) => data.productive,
                            name: 'Productive',
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            animationDuration: 1200,
                          ),
                          ColumnSeries<_TrendData, String>(
                            dataSource: _getWeeklyTrend(),
                            xValueMapper: (_TrendData data, _) => data.day,
                            yValueMapper: (_TrendData data, _) => data.unproductive,
                            name: 'Unproductive',
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            animationDuration: 1200,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSectionHeader('Most Productive Hours'),
                    _buildChartCard(
                      height: 250,
                      child: SfCartesianChart(
                        primaryXAxis: NumericAxis(
                          title: AxisTitle(text: 'Hour of Day'),
                          minimum: 0,
                          maximum: 24,
                          interval: 4,
                        ),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Productive Entries'),
                        ),
                        palette: const <Color>[
                          Color(0xFF4CAF50),
                        ],
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          SplineSeries<_HourlyData, double>(
                            dataSource: _getHourlyDistribution(),
                            xValueMapper: (_HourlyData data, _) => data.hour.toDouble(),
                            yValueMapper: (_HourlyData data, _) => data.count,
                            markerSettings: MarkerSettings(isVisible: true),
                            animationDuration: 1200,
                            name: 'Productive Entries',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSectionHeader('Note Keyword Frequency'),
                    _buildChartCard(
                      height: 250,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        zoomPanBehavior: ZoomPanBehavior(
                          enablePanning: true,
                          zoomMode: ZoomMode.x,
                        ),
                        palette: const <Color>[
                          Color(0xFF2196F3),
                        ],
                        series: <CartesianSeries>[
                          ColumnSeries<MapEntry<String, int>, String>(
                            dataSource: _getNoteKeywords().entries.toList(),
                            xValueMapper: (MapEntry<String, int> data, _) => data.key,
                            yValueMapper: (MapEntry<String, int> data, _) => data.value,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            animationDuration: 1200,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildChartCard({required Widget child, required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
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
