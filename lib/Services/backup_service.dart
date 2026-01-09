import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:intl/intl.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> checkAndPerformBackup() async {
    String? lastBackupStr = await _dbHelper.getSetting('last_backup_date');
    DateTime now = DateTime.now();

    if (lastBackupStr == null || lastBackupStr.isEmpty) {
      // First time backup
      await performBackup();
      return;
    }

    DateTime lastBackup = DateTime.parse(lastBackupStr);
    if (now.difference(lastBackup).inDays >= 15) {
      await performBackup();
    }
  }

  Future<void> performBackup() async {
    try {
      Directory? appDocDir = await getExternalStorageDirectory(); // Or getApplicationDocumentsDirectory()
      if (appDocDir == null) {
        appDocDir = await getApplicationDocumentsDirectory();
      }

      String backupDirPath = join(appDocDir.path, 'backups');
      Directory backupDir = Directory(backupDirPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      String dbPath = join(await getDatabasesPath(), 'pos_database.db');
      File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
        String backupPath = join(backupDirPath, 'pos_backup_$timestamp.db');
        await dbFile.copy(backupPath);

        // Update last backup date
        await _dbHelper.updateSetting('last_backup_date', DateTime.now().toIso8601String());
        print('Backup successful: $backupPath');
      } else {
        print('Database file not found for backup.');
      }
    } catch (e) {
      print('Error during backup: $e');
    }
  }
}
