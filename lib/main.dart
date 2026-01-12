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
  print('Application starting...');
  
  try {
    // Initialize Database
    print('Initializing Database...');
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    print('Database initialized.');
    
    // Initialize AuthController globally
    Get.put(AuthController());
    
    // Check and perform backup if 15 days passed
    print('Checking backup...');
    final backupService = BackupService();
    await backupService.checkAndPerformBackup();
    print('Backup check completed.');
    
    // Initialize Supabase
    print('Initializing Supabase...');
    final supabaseService = SupabaseService();
    await supabaseService.initialize().timeout(const Duration(seconds: 10), onTimeout: () {
      print('Supabase initialization timed out.');
    });
    print('Supabase initialized.');
    
    // Start Sync Service
    final syncService = SyncService();
    syncService.startSyncMonitoring();
    
    print('Running App...');
    runApp(const MyApp());
  } catch (e, stack) {
    print('Fatal Error during initialization: $e');
    print(stack);
    // Run app with error screen or minimal app to show error
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Error: $e')))));
  }
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
