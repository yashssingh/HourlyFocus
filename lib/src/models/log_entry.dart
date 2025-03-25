class LogEntry {
  final int? id;
  final DateTime timestamp;
  final String status;
  final String note;

  LogEntry({
    this.id,
    required this.timestamp,
    required this.status,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'note': note,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'],
      note: map['note'],
    );
  }
}
