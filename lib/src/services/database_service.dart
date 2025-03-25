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
}
