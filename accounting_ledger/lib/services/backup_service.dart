// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class BackupService {
  static Future<String> createBackup() async {
    final data = await DatabaseService.exportAll();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${dir.path}/backup_$timestamp.json');
    await file.writeAsString(json);
    return file.path;
  }

  static Future<void> restoreFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found: $filePath');
    }
    final json = await file.readAsString();
    final data = jsonDecode(json) as Map<String, dynamic>;
    await DatabaseService.importAll(data);
  }

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.single.path;
  }

  static Future<List<FileSystemEntity>> listBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .where((f) =>
            f is File &&
            f.path.contains('backup_') &&
            f.path.endsWith('.json'))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  static Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
