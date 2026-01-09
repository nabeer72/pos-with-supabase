import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pos/Services/supabase_service.dart';

class SyncService {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final SupabaseService _supabaseService = SupabaseService();

  void startSyncMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.ethernet)) {
        print("Connected to internet. Starting sync...");
        _supabaseService.syncData();
      }
    });

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
       if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.ethernet)) {
        _supabaseService.syncData();
      }
    });
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}
