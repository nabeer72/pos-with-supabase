import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> checkAndPerformBackup() async {
    final adminId = Get.find<AuthController>().adminId;
    if (adminId == null) return;

    // Check if auto backup is enabled for this admin
    String? autoBackupEnabled = await _dbHelper.getSetting('auto_backup_enabled', adminId: adminId);
    if (autoBackupEnabled == 'false') {
      print('Auto backup disabled for admin: $adminId');
      return;
    }

    String? lastBackupStr = await _dbHelper.getSetting('last_backup_date', adminId: adminId);
    DateTime now = DateTime.now();

    if (lastBackupStr == null || lastBackupStr.isEmpty) {
      // First time backup
      await performBackup(adminId: adminId);
      return;
    }

    DateTime lastBackup = DateTime.parse(lastBackupStr);
    
    // Fetch custom frequency settings
    int freqValue = await getBackupFrequency(adminId);
    String freqUnit = await getBackupFrequencyUnit(adminId);

    bool isDue = false;
    if (freqUnit == 'days') {
      isDue = now.difference(lastBackup).inDays >= freqValue;
    } else if (freqUnit == 'months') {
      DateTime nextBackupDate = DateTime(lastBackup.year, lastBackup.month + freqValue, lastBackup.day);
      isDue = now.isAfter(nextBackupDate) || now.isAtSameMomentAs(nextBackupDate);
    } else if (freqUnit == 'years') {
      DateTime nextBackupDate = DateTime(lastBackup.year + freqValue, lastBackup.month, lastBackup.day);
      isDue = now.isAfter(nextBackupDate) || now.isAtSameMomentAs(nextBackupDate);
    }

    if (isDue) {
      await performBackup(adminId: adminId);
    }
  }


  Future<void> performBackup({String? adminId}) async {
    try {
      final currentAdminId = adminId ?? Get.find<AuthController>().adminId;
      if (currentAdminId == null) return;

      Directory? appDocDir = await getExternalStorageDirectory();
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
        String backupPath = join(backupDirPath, 'pos_backup_admin_${currentAdminId}_$timestamp.db');
        await dbFile.copy(backupPath);

        // Update last backup date for THIS admin
        await _dbHelper.updateSetting('last_backup_date', DateTime.now().toIso8601String(), adminId: currentAdminId);
        print('Backup successful for admin $currentAdminId: $backupPath');
      } else {
        print('Database file not found for backup.');
      }
    } catch (e) {
      print('Error during backup: $e');
    }
  }

  Future<bool> isAutoBackupEnabled(String adminId) async {
    String? val = await _dbHelper.getSetting('auto_backup_enabled', adminId: adminId);
    return val != 'false'; // Default to true
  }

  Future<void> setAutoBackupEnabled(String adminId, bool enabled) async {
    await _dbHelper.updateSetting('auto_backup_enabled', enabled.toString(), adminId: adminId);
  }

  Future<bool> isManualBackupEnabled(String adminId) async {
    String? val = await _dbHelper.getSetting('manual_backup_enabled', adminId: adminId);
    return val != 'false'; // Default to true
  }

  Future<void> setManualBackupEnabled(String adminId, bool enabled) async {
    await _dbHelper.updateSetting('manual_backup_enabled', enabled.toString(), adminId: adminId);
  }

  Future<int> getBackupFrequency(String adminId) async {
    String? val = await _dbHelper.getSetting('backup_frequency_value', adminId: adminId);
    return int.tryParse(val ?? '7') ?? 7;
  }

  Future<void> setBackupFrequency(String adminId, int value) async {
    await _dbHelper.updateSetting('backup_frequency_value', value.toString(), adminId: adminId);
  }

  Future<String> getBackupFrequencyUnit(String adminId) async {
    String? val = await _dbHelper.getSetting('backup_frequency_unit', adminId: adminId);
    return val ?? 'days';
  }

  Future<void> setBackupFrequencyUnit(String adminId, String unit) async {
    await _dbHelper.updateSetting('backup_frequency_unit', unit, adminId: adminId);
  }
}
