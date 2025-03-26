import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/log_entry.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'hourly_focus.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE logs (id INTEGER PRIMARY KEY, timestamp TEXT, status TEXT, note TEXT)',
        );
      },
    );
  }

  Future<void> insertLog(LogEntry log) async {
    final db = await database;
    await db.insert(
      'logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LogEntry>> getLogsForDay(DateTime day) async {
    final db = await database;
    final logs = await db.query(
      'logs',
      where: 'timestamp LIKE ?',
      whereArgs: ['${day.toIso8601String().substring(0, 10)}%'],
    );
    return logs.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<List<LogEntry>> getLogsBetweenDates(DateTime startDate, DateTime endDate) async {
    final db = await database;
    
    // Format dates to ISO string and compare only the date part (not time)
    final startString = startDate.toIso8601String().substring(0, 10);
    final endString = endDate.toIso8601String().substring(0, 10);
    
    final logs = await db.query(
      'logs',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: ['$startString 00:00:00.000Z', '$endString 23:59:59.999Z'],
    );
    
    return logs.map((map) => LogEntry.fromMap(map)).toList();
  }

  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete(
      'logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
