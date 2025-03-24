import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initNotifications();
  runApp(HourlyFocusApp());
}

Future<void> initNotifications() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
    initSettings,
  );
  print('Notifications initialized: $initialized');

  await scheduleTestNotifications(flutterLocalNotificationsPlugin);
}

Future<void> scheduleTestNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  const androidDetails = AndroidNotificationDetails(
    'hourly_focus',
    'Hourly Check-In',
    channelDescription: 'Prompts for productivity tracking',
    importance: Importance.max, // Ensure visibility
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true, // Force alert in Simulator
    presentBadge: true,
    presentSound: true,
  );
  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  // Immediate test notification
  await plugin.show(
    0,
    'Immediate Test',
    'This should show right away!',
    notificationDetails,
  );
  print('Immediate notification triggered');

  // Scheduled test notification (10 seconds)
  final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: 10));
  await plugin.zonedSchedule(
    999,
    'Test Notification',
    'This should appear in 10 seconds!',
    scheduledTime,
    notificationDetails,
    matchDateTimeComponents: DateTimeComponents.time,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
  print('Notification scheduled for: $scheduledTime');
}

class HourlyFocusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HourlyFocus',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Database? _db;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _loadLogs();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'hourly_focus.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE logs (id INTEGER PRIMARY KEY, timestamp TEXT, status TEXT, note TEXT)',
        );
      },
    );
  }

  Future<void> _loadLogs() async {
    if (_db != null) {
      final logs = await _db!.query(
        'logs',
        where: 'timestamp LIKE ?',
        whereArgs: ['${DateTime.now().toIso8601String().substring(0, 10)}%'],
      );
      setState(() => _logs = logs);
    }
  }

  Future<void> _logHour(String status, {String? note}) async {
    if (_db != null) {
      await _db!.insert('logs', {
        'timestamp': DateTime.now().toIso8601String(),
        'status': status,
        'note': note ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HourlyFocus'),
        elevation: 0,
        backgroundColor: Colors.teal,
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            height: 250,
            padding: EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                barGroups:
                    _logs.map((log) {
                      final isProductive = log['status'] == 'productive';
                      return BarChartGroupData(
                        x: DateTime.parse(log['timestamp']).hour,
                        barRods: [
                          BarChartRodData(
                            toY: 1.0,
                            color: isProductive ? Colors.green : Colors.red,
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 1.5,
                gridData: FlGridData(show: false),
              ),
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                padding: EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final hour = DateTime.parse(log['timestamp']).hour;
                  return ListTile(
                    leading: Icon(
                      log['status'] == 'productive'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color:
                          log['status'] == 'productive'
                              ? Colors.green
                              : Colors.red,
                    ),
                    title: Text('$hour:00 - ${log['status']}'),
                    subtitle: log['note'].isNotEmpty ? Text(log['note']) : null,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.check),
                  label: Text('Productive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _logHour('productive'),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.close),
                  label: Text('Unproductive'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _logHour('unproductive'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
