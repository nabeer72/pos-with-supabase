import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var currentUser = <String, dynamic>{}.obs;
  var userPermissions = <String>[].obs;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void login(Map<String, dynamic> user) {
    isLoggedIn.value = true;
    currentUser.value = user;
    
    // Parse permissions from JSON string
    try {
      if (user['permissions'] != null) {
        final List<dynamic> decoded = jsonDecode(user['permissions']);
        userPermissions.value = decoded.map((e) => e.toString()).toList();
      } else {
        userPermissions.value = [];
      }
    } catch (e) {
      print('Error parsing permissions: $e');
      userPermissions.value = [];
    }
    
    // Initialize currency service for this admin
    final currencyService = CurrencyService();
    final currentAdminId = adminId;
    if (currentAdminId != null) {
      currencyService.setCurrentAdminId(currentAdminId);
      currencyService.loadCurrency(); // Load currency asynchronously
      currencyService.initializeCurrencyForAdmin(currentAdminId); // Ensure default currency is set
    }
  }

  void logout() async {
    isLoggedIn.value = false;
    currentUser.value = {};
    userPermissions.value = [];
    
    // Clear local business data on logout to prevent sharing data on shared devices
    await _dbHelper.clearLocalData();
    
    // Reset currency service cache
    CurrencyService().resetCache();
    
    try {
      await SupabaseService().signOut();
    } catch(e) {
      print("Error signing out from supabase: $e");
    }
  }

  bool hasPermission(String permission) {
    if (userRole == 'Admin') return true; // Admin has all permissions implicitly
    if (userPermissions.contains('all')) return true;
    return userPermissions.contains(permission);
  }

  String get userRole => currentUser['role'] ?? 'Guest';
  
  bool get isAdmin => userRole == 'Admin';

  String get userName => currentUser['name'] ?? 'Unknown';

  Future<void> loginWithSupabase(String email, String password) async {
    try {
      // 1. Sign in with Supabase
      final response = await SupabaseService().signIn(email, password);
      
      if (response.user != null) {
        // 2. Fetch User Profile
        final userProfile = await SupabaseService().getUserProfile(email);
        
        if (userProfile != null) {
          // 3. Sync to Local Database
          // Check if user exists locally
          final existingUser = await _dbHelper.getUserByEmail(email);
          
          final userToSync = {
            'name': userProfile['name'],
            'email': email,
            'role': userProfile['role'],
            'permissions': userProfile['permissions'],
            'lastActive': DateTime.now().toString(),
            'is_synced': 1,
            'supabase_id': userProfile['id'],
            'adminId': userProfile['admin_id'], // Sync adminId from remote
            'password': password
          };

          if (existingUser != null) {
             await _dbHelper.updateUser(existingUser['id'], userToSync);
          } else {
             await _dbHelper.insertUser(userToSync);
          }
           
          // 4. Perform Local Login to set state
          final localUser = await _dbHelper.getUserByEmail(email);
          if (localUser != null) {
            login(localUser);
            
            // 5. Pull all remote data immediately after login
            SupabaseService().pullRemoteData(); 
            return;
          }
        }
      }
      throw const AuthException('Login failed: User profile could not be retrieved.');
    } on AuthException catch (e) {
      print('Supabase Auth Error: ${e.message}');
      
      // Attempt bypass for "Email not confirmed" if the user just wants to log in
      // and RLS allows reading the profile without a session.
      if (e.message.contains('Email not confirmed')) {
        print('Email not confirmed, attempting to fetch profile anyway...');
        
        // 2. Fetch User Profile (Try without session)
        final userProfile = await SupabaseService().getUserProfile(email);
        
        if (userProfile != null) {
           print('Profile found regardless of auth error. Proceeding with sync.');
           // 3. Sync to Local Database
           final existingUser = await _dbHelper.getUserByEmail(email);
          
           final userToSync = {
            'name': userProfile['name'],
            'email': email,
            'role': userProfile['role'],
            'permissions': userProfile['permissions'],
            'lastActive': DateTime.now().toString(),
            'is_synced': 1,
            'supabase_id': userProfile['id'],
            'adminId': userProfile['admin_id'], 
            'password': password
           };

           if (existingUser != null) {
              await _dbHelper.updateUser(existingUser['id'], userToSync);
           } else {
              await _dbHelper.insertUser(userToSync);
           }
           
           // 4. Perform Local Login
           final localUser = await _dbHelper.getUserByEmail(email);
           if (localUser != null) {
             login(localUser);
             // 5. Pull remote data (might fail if RLS requires auth, but user profile was open)
             SupabaseService().pullRemoteData(); 
             return; // Success bypass
           }
        }
      }
      rethrow; // Rethrow if bypass failed
    } catch (e) {
      print('LoginWithSupabase Error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if user exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        return false; // Email already taken
      }

      final newUser = {
        'name': name,
        'email': email,
        'password': password,
        'role': 'Admin', // Default to Admin for public signup
        'lastActive': DateTime.now().toString(),
        'permissions': jsonEncode(['all']), // Admin gets all permissions
        'is_synced': 0, // Flag for sync
        'adminId': null, // Will be set to own ID or handled by sync logic. Actually for Admin, adminId is their own ID. 
                         // But we don't have ID yet. We can update it after insertion or use UUID. 
                         // For simplicity, let's treat NULL adminId as "Root/Self" or update after insert.
      };

      final id = await _dbHelper.insertUser(newUser);
      final String adminIdForNewUser = id.toString();
      // Update adminId to be the same as the user ID for Admins so they are their own Tenant
      await _dbHelper.updateUser(id, {'adminId': adminIdForNewUser});
      
      // Seed default categories for this new admin
      await _dbHelper.seedCategoriesForAdmin(adminIdForNewUser);
      
      // Trigger sync to push user to Supabase
      SupabaseService().syncData();
      
      return true;
    } catch (e) {
      print('SignUp Error: $e');
      return false;
    }
  }

  String? get adminId {
    if (currentUser['role'] == 'Admin') {
      return currentUser['adminId'] ?? currentUser['id'].toString();
    } else {
      return currentUser['adminId'];
    }
  }
}
