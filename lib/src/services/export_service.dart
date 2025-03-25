import 'dart:io';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../models/log_entry.dart';

class ExportService {
  Future<String> _generateCsv(List<LogEntry> logs) async {
    if (logs.isEmpty) return '';
    final csvData = ListToCsvConverter().convert([
      ['Hour', 'Status', 'Note'],
      ...logs.map((log) => [
            log.timestamp.hour.toString(),
            log.status,
            log.note,
          ]),
    ]);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/daily_logs.csv';
    final file = File(path);
    await file.writeAsString(csvData);
    return path;
  }

  Future<void> exportViaEmail(List<LogEntry> logs) async {
    final path = await _generateCsv(logs);
    if (path.isNotEmpty) {
      await Share.shareFiles([path], text: 'Daily Productivity Logs');
    }
  }

  Future<void> exportToGoogleDrive(List<LogEntry> logs) async {
    final path = await _generateCsv(logs);
    if (path.isEmpty) return;

    // Placeholder for Google Drive auth - replace with your credentials
    final client = http.Client();
    final credentials = await obtainAccessCredentialsViaUserConsent(
      ClientId(
          '20064200264-jgk2nct5dlgn39b987bm2nsv9n30hv05.apps.googleusercontent.com',
          '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'), // Replace with actual values
      ['https://www.googleapis.com/auth/drive.file'],
      client,
      (url) async {
        print('Open this URL in a browser and paste the code: $url');
        // In a real app, you would implement a way to get the code from the user
        return Future.value('');
      },
    );

    final authClient = authenticatedClient(http.Client(), credentials);
    final driveApi = drive.DriveApi(authClient);

    final file = drive.File()
      ..name = 'daily_logs_${DateTime.now().toIso8601String()}.csv'
      ..mimeType = 'text/csv';
    final media = drive.Media(File(path).openRead(), File(path).lengthSync());
    await driveApi.files.create(file, uploadMedia: media);
    authClient.close();
  }
}
