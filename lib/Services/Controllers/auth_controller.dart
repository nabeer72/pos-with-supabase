import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/currency_service.dart';
import 'package:pos/Screens/button_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;
  var currentUser = <String, dynamic>{}.obs;
  var userPermissions = <String>[].obs;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  @override
  void onInit() {
    super.onInit();
    // Listen for Auth Changes (Deep Links, manual sign-ins, etc)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('=== DEBUG: AuthStateChange Detected ===');
      print('Event: $event');
      print('Session User ID: ${session?.user.id}');
      print('Session Active: ${session != null}');

      if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) && session != null) {
        // If we have a session but aren't locally logged in, trigger "Late Sync" and Auto-Login
        if (!isLoggedIn.value) {
          final email = session.user.email;
          if (email != null) {
            print('DEBUG: Session detected for $email. Initiating Late Sync sequence...');
            await _handleAutoLoginAfterConfirmation(email, session.user.id);
          }
        } else {
          print('DEBUG: User already locally logged in. Skipping auto-sync.');
        }
      }
    });
  }

  Future<void> _handleAutoLoginAfterConfirmation(String email, String supabaseUid) async {
    print('=== DEBUG: _handleAutoLoginAfterConfirmation START ===');
    try {
      // 1. Try to fetch profile from remote
      print('DEBUG: Fetching Remote Profile for $email...');
      var profile = await SupabaseService().getUserProfile(email);

      if (profile == null) {
        print('DEBUG: Profile NOT FOUND on remote. Checking Local SQLite...');
        // 2. If profile is missing on remote, check local
        final localUser = await _dbHelper.getUserByEmail(email);
        if (localUser != null) {
          print('DEBUG: Local profile found. Syncing to Supabase with ID: $supabaseUid');
          // Ensure local record has the correct Auth UUID
          await _dbHelper.updateUser(localUser['id'], {'supabase_id': supabaseUid});
          
          // Trigger manual push sync for the user
          print('DEBUG: Triggering pushUnsyncedData for user profile...');
          await SupabaseService().pushUnsyncedData();
          
          // Try fetching again to confirm
          profile = await SupabaseService().getUserProfile(email);
          print('DEBUG: Fetched remote profile after sync: ${profile != null}');
        } else {
          print('DEBUG: Local profile NOT FOUND. Cannot proceed with late sync.');
        }
      } else {
        print('DEBUG: Remote profile found immediately.');
      }

      if (profile != null) {
         // 3. Sync local state and navigate
         final localUser = await _dbHelper.getUserByEmail(email);
         if (localUser != null) {
           login(localUser);
           // Auto-redirect to dashboard
           Get.offAll(() => BottomNavigation());
         }
      }
    } catch (e) {
      print('Error during auto-login/sync: $e');
    }
  }

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
    // Commented out to allow local users (Cashiers) to see data on shared devices
    // await _dbHelper.clearLocalData(); 
    
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
        var userProfile = await SupabaseService().getUserProfile(email);
        
        if (userProfile == null) {
          print('User profile not found on Supabase. Attempting to push local profile...');
          final localUser = await _dbHelper.getUserByEmail(email);
          if (localUser != null) {
             // Link the Auth UID to the local user if not already set
             await _dbHelper.updateUser(localUser['id'], {'supabase_id': response.user?.id});
             
             // Trigger a manual sync for this user
             await SupabaseService().pushUnsyncedData();
             
             // Try fetching again
             userProfile = await SupabaseService().getUserProfile(email);
          }
        }
        
        if (userProfile != null) {
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
            
            // 5. Pull remote data in background (non-blocking)
            print("Starting background data sync...");
            SupabaseService().pullRemoteData().then((_) {
              Get.snackbar('Sync Complete', 'Your data has been synchronized',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2));
            }).catchError((e) {
              print('Background sync error: $e');
            });
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
             // 5. Pull remote data in background (non-blocking)
             print("Starting background data sync...");
             SupabaseService().pullRemoteData().then((_) {
              
             }).catchError((e) {
               print('Background sync error: $e');
             });
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

  Future<bool> signUp(String name, String email, String password, {String? supabaseId}) async {
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
        'supabase_id': supabaseId,
        'adminId': null, // Will be set to own ID or handled by sync logic. Actually for Admin, adminId is their own ID. 
      };

      final id = await _dbHelper.insertUser(newUser);
      
      // Use the global Supabase UID as the Admin ID if available, otherwise fallback to local ID
      final String adminIdForNewUser = supabaseId ?? id.toString();
      
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
      // For Admin, prefer adminId column, then supabase_id, then local id
      return (currentUser['adminId'] ?? currentUser['supabase_id'] ?? currentUser['id'])?.toString();
    } else {
      return currentUser['adminId']?.toString();
    }
  }
}
