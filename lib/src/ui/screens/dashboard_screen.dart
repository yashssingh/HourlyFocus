import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:hourly_focus/src/services/database_service.dart';
import 'package:hourly_focus/src/services/export_service.dart';
import 'package:hourly_focus/src/services/notification_service.dart';
import 'package:hourly_focus/src/ui/widgets/daily_log_form.dart';
import 'package:hourly_focus/src/ui/widgets/daily_summary_card.dart';
import 'package:hourly_focus/src/ui/widgets/hourly_heatmap_chart.dart';
import 'package:hourly_focus/src/ui/widgets/productivity_line_chart.dart';
import 'package:hourly_focus/src/ui/widgets/weekly_productivity_chart.dart';
import 'package:hourly_focus/src/ui/widgets/productivity_score_card.dart';
import 'package:hourly_focus/src/ui/widgets/mood_distribution_card.dart';
import 'package:intl/intl.dart';
import 'package:hourly_focus/src/ui/screens/analytics_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DashboardScreen extends StatefulWidget {
  final NotificationService notificationService;

  DashboardScreen({required this.notificationService});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();
  final ExportService _exportService = ExportService();
  List<LogEntry> _logs = [];
  List<LogEntry> _weeklyLogs = [];
  bool _isLoading = true;
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedDate = DateTime.now();
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _requestPermissions();
    _loadData();
    _checkNotificationLaunch();
    widget.notificationService.scheduleHourlyNotifications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _checkNotificationLaunch() async {
    // Check if app was launched from a notification
    final details = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final String? actionId = details?.notificationResponse?.actionId;
      if (actionId != null) {
        _logHourFromNotification(actionId);
      }
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    
    final dailyLogs = await _dbService.getLogsForDay(_selectedDate);
    final weeklyLogs = await _dbService.getLogsBetweenDates(
      weekStart, 
      weekStart.add(Duration(days: 7))
    );

    if (mounted) {
      setState(() {
        _logs = dailyLogs;
        _weeklyLogs = weeklyLogs;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _logHour(String status) async {
    final log = LogEntry(
      timestamp: DateTime.now(),
      status: status,
      note: _noteController.text,
    );
    await _dbService.insertLog(log);
    _noteController.clear();
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as $status'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(8),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logHourFromNotification(String action) async {
    if (action == 'productive' || action == 'unproductive') {
      final log = LogEntry(
        timestamp: DateTime.now(),
        status: action,
        note: 'Logged from notification',
      );
      await _dbService.insertLog(log);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as $action from notification'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(8),
            duration: Duration(seconds: 2),
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _showExportOptions() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Logs'),
        content: Text('Choose export method:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'email'),
            child: Text('Email'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'drive'),
            child: Text('Google Drive'),
          ),
        ],
      ),
    );

    if (choice == 'email') {
      await _exportService.exportViaEmail(_logs);
    } else if (choice == 'drive') {
      await _exportService.exportToGoogleDrive(_logs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.brightness == Brightness.light 
          ? Color(0xFFF5F7FA) 
          : Color(0xFF121212),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _selectDate(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16),
              SizedBox(width: 8),
              Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.insert_chart), text: 'Analytics'),
          ],
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: true,
            enableDrag: true,
            builder: (context) {
              return SingleChildScrollView(
                child: DailyLogForm(
                  onProductivePressed: () {
                    Navigator.pop(context);
                    _logHour('productive');
                  },
                  onUnproductivePressed: () {
                    Navigator.pop(context);
                    _logHour('unproductive');
                  },
                  noteController: _noteController,
                ),
              );
            },
          ).catchError((error) {
            print('Error showing modal bottom sheet: $error');
            // Show an error message to the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open log form. Please try again.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        },
        label: Text('Log Hour'),
        icon: Icon(Icons.add),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildTodayTab(),
          AnalyticsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'Productivity Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slide(begin: Offset(0, -0.1), duration: 500.ms),
        
        SizedBox(height: 16),
        
        StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 0.8,
              child: ProductivityScoreCard(logs: _weeklyLogs)
                .animate(controller: _animationController)
                .fadeIn(duration: 600.ms)
                .scale(begin: Offset(0.9, 0.9)),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1.2,
              child: DailySummaryCard(logs: _logs, date: _selectedDate)
                .animate(controller: _animationController)
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .scale(begin: Offset(0.9, 0.9)),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1.2,
              child: MoodDistributionCard(logs: _weeklyLogs)
                .animate(controller: _animationController)
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .scale(begin: Offset(0.9, 0.9)),
            ),
          ],
        ),
        
        SizedBox(height: 20),
        
        Text(
          'Weekly Trends',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
        .animate(controller: _animationController)
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slide(begin: Offset(0, -0.1)),
        
        SizedBox(height: 12),
        
        Container(
          height: 250,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: WeeklyProductivityChart(logs: _weeklyLogs),
            ),
          ),
        )
        .animate(controller: _animationController)
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .slide(begin: Offset(0, 0.1)),
        
        SizedBox(height: 20),
        
        Text(
          'Hourly Productivity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
        .animate(controller: _animationController)
        .fadeIn(duration: 500.ms, delay: 500.ms)
        .slide(begin: Offset(0, -0.1)),
        
        SizedBox(height: 12),
        
        Container(
          height: 200,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: HourlyHeatmapChart(logs: _weeklyLogs),
            ),
          ),
        )
        .animate(controller: _animationController)
        .fadeIn(duration: 800.ms, delay: 600.ms)
        .slide(begin: Offset(0, 0.1)),
        
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTodayTab() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }
    
    final todayLogs = _logs.where((log) {
      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      final selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return logDate.isAtSameMomentAs(selectedDate);
    }).toList();
    
    final productiveCount = todayLogs.where((log) => log.status == 'productive').length;
    final unproductiveCount = todayLogs.where((log) => log.status == 'unproductive').length;
    final totalCount = todayLogs.length;
    final productivityRate = totalCount > 0 ? (productiveCount / totalCount) * 100 : 0.0;
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.thumb_up,
                      color: Colors.green,
                      title: 'Productive',
                      value: '$productiveCount hrs',
                    ),
                    _buildSummaryItem(
                      icon: Icons.thumb_down,
                      color: Colors.red,
                      title: 'Unproductive',
                      value: '$unproductiveCount hrs',
                    ),
                    _buildSummaryItem(
                      icon: Icons.stacked_line_chart,
                      color: Theme.of(context).colorScheme.primary,
                      title: 'Success Rate',
                      value: '${productivityRate.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: Offset(0.95, 0.95)),
        
        SizedBox(height: 20),
        
        Text(
          'Today\'s Productivity Timeline',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        
        SizedBox(height: 12),
        
        Container(
          height: 250,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ProductivityLineChart(logs: todayLogs),
            ),
          ),
        ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
        
        SizedBox(height: 20),
        
        Text(
          'Activity Logs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        
        SizedBox(height: 12),
        
        todayLogs.isEmpty
            ? Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No logs for today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to log your productivity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 400.ms)
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: todayLogs.length,
                itemBuilder: (context, index) {
                  final log = todayLogs[index];
                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: log.status == 'productive'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          log.status == 'productive'
                              ? Icons.check
                              : Icons.close,
                          color: log.status == 'productive'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      title: Text(
                        log.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: log.status == 'productive'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(log.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          if (log.note.isNotEmpty)
                            Text(
                              log.note,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _dbService.deleteLog(log.id ?? 0);
                          _loadData();
                        },
                      ),
                    ),
                  ).animate().fadeIn(
                        duration: 400.ms,
                        delay: Duration(milliseconds: 100 * index),
                      );
                },
              ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 32,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              height: 32,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
} 