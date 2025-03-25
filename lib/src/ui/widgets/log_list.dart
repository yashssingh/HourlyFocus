import 'package:flutter/material.dart';
import '../../models/log_entry.dart';

class LogList extends StatelessWidget {
  final List<LogEntry> logs;

  LogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        itemCount: logs.length,
        padding: EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: Icon(
              log.status == 'productive' ? Icons.check_circle : Icons.cancel,
              color: log.status == 'productive' ? Colors.green : Colors.red,
            ),
            title: Text('${log.timestamp.hour}:00 - ${log.status}'),
            subtitle: log.note.isNotEmpty ? Text(log.note) : null,
          );
        },
      ),
    );
  }
}
