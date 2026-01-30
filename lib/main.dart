import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:pos/Screens/Loader/loader.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/backup_service.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/sync_service.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:pos/Services/loyalty_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Application starting...');
  
  try {
    print('Starting initialization sequence...');
    // Initialize Database
    print('Step 1: Initializing Database...');
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    print('Step 1: Database initialized successfully.');
    
    // Initialize AuthController globally
    print('Step 2: Initializing AuthController...');
    Get.put(AuthController());
    print('Step 2: AuthController initialized.');
    
    // Check and perform backup if 15 days passed
    print('Step 3: Checking backup status...');
    final backupService = BackupService();
    await backupService.checkAndPerformBackup();
    print('Step 3: Backup check completed.');
    
    // Initialize Supabase
    print('Step 4: Initializing Supabase...');
    final supabaseService = SupabaseService();
    try {
      await supabaseService.initialize().timeout(const Duration(seconds: 15), onTimeout: () {
        print('Supabase initialization timed out');
      });
      // Perform one-time cleanup of trial concepts
      await supabaseService.cleanupTrialConcepts();
    } catch (e) {
      print('Supabase initialization error: $e');
    }
    
    // Start Sync Service
    print('Step 5: Starting Sync Service...');
    final syncService = SyncService();
    syncService.startSyncMonitoring();
    print('Step 5: Sync Service started.');
    
    // Initialize LoyaltyService
    print('Step 6: Initializing LoyaltyService...');
    Get.put(LoyaltyService());
    print('Step 6: LoyaltyService initialized.');
    
    print('All initialization steps completed. Launching MyApp...');
    runApp(const MyApp());
  } catch (e, stack) {
    print('CRITICAL FAILURE during initialization: $e');
    print('Stack trace: $stack');
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text('App Failed to Start', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pos',
     
      home: SplashScreen(),
    );
  }
}
