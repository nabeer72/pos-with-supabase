import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:pos/Screens/Loader/loader.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/backup_service.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  // Initialize AuthController globally
  Get.put(AuthController());
  
  // Check and perform backup if 15 days passed
  final backupService = BackupService();
  await backupService.checkAndPerformBackup();
  
  // Initialize Supabase
  final supabaseService = SupabaseService();
  await supabaseService.initialize();
  
  // Start Sync Service
  final syncService = SyncService();
  syncService.startSyncMonitoring();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
     
      home: SplashScreen(),
    );
  }
}
