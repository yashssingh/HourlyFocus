import 'package:flutter/material.dart';
import 'package:hourly_focus/src/models/log_entry.dart';
import 'package:hourly_focus/src/services/database_service.dart';
import 'package:hourly_focus/src/services/export_service.dart';
import 'package:hourly_focus/src/services/notification_service.dart';
import 'package:hourly_focus/src/ui/widgets/log_list.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  final NotificationService notificationService;

  HomeScreen({required this.notificationService});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();
  final ExportService _exportService = ExportService();
  final TextEditingController _noteController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  List<LogEntry> _logs = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _loadLogs();
    _checkNotificationLaunch();
    widget.notificationService.scheduleHourlyNotifications();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload logs when the app is resumed, which might happen after
    // responding to a notification from the lock screen
    if (state == AppLifecycleState.resumed) {
      _loadLogs();
    }
  }

  Future<void> _checkNotificationLaunch() async {
    // Check if app was launched from a notification
    final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final String? actionId = details?.notificationResponse?.actionId;
      if (actionId != null) {
        _logHourFromNotification(actionId);
      }
    }
    
    // Set up handling for future notification actions
    _setUpNotificationActionHandler();
  }
  
  void _setUpNotificationActionHandler() {
    // Listen for notification actions when app is running
    _notificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId != null) {
          _logHourFromNotification(response.actionId!);
        }
      },
    );
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    
    // Request notification permissions
    await Permission.notification.request();
    
    // For iOS, request critical notifications permission
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

  Future<void> _loadLogs() async {
    final logs = await _dbService.getLogsForDay(DateTime.now());
    setState(() => _logs = logs);
  }

  Future<void> _logHour(String status) async {
    final log = LogEntry(
      timestamp: DateTime.now(),
      status: status,
      note: _noteController.text,
    );
    await _dbService.insertLog(log);
    _noteController.clear();
    _loadLogs();
  }

  // Handle lock screen notification actions
  Future<void> _logHourFromNotification(String action) async {
    if (action == 'productive' || action == 'unproductive') {
      final log = LogEntry(
        timestamp: DateTime.now(),
        status: action,
        note: 'Logged from notification',
      );
      await _dbService.insertLog(log);
      
      // Show a confirmation toast or snackbar when the app is visible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked hour as $action from notification'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      _loadLogs();
    }
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) =>
              setState(() => _noteController.text = result.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No logs to export')));
    }
  }

  List<_PieChartData> _getPieChartData() {
    final productiveCount =
        _logs.where((log) => log.status == 'productive').length;
    final unproductiveCount =
        _logs.where((log) => log.status == 'unproductive').length;
    final total = productiveCount + unproductiveCount;

    if (total == 0) {
      return [_PieChartData('No Data', 1, Colors.grey)];
    }

    return [
      _PieChartData('Productive', productiveCount.toDouble(), Colors.green),
      _PieChartData('Unproductive', unproductiveCount.toDouble(), Colors.red),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HourlyFocus'),
        elevation: 0,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh logs',
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.teal,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Today\'s Productivity',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            height: 250,
            padding: EdgeInsets.all(16),
            child: SfCircularChart(
              legend: Legend(isVisible: true, position: LegendPosition.bottom),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CircularSeries>[
                PieSeries<_PieChartData, String>(
                  dataSource: _getPieChartData(),
                  xValueMapper: (_PieChartData data, _) => data.category,
                  yValueMapper: (_PieChartData data, _) => data.value,
                  pointColorMapper: (_PieChartData data, _) => data.color,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.inside,
                    textStyle: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  enableTooltip: true,
                ),
              ],
            ),
          ),
          Expanded(child: LogList(logs: _logs)),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Add a note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      label: Text('Productive'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () => _logHour('productive'),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('Unproductive'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _logHour('unproductive'),
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _toggleListening,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _speech.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _PieChartData {
  final String category;
  final double value;
  final Color color;

  _PieChartData(this.category, this.value, this.color);
}
