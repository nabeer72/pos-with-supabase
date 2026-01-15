import 'package:get/get.dart';
import 'dart:convert';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/currency_service.dart';

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

  Future<bool> loginWithSupabase(String email, String password) async {
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
            'email': email, // Ensure email is consistent
            'role': userProfile['role'],
            'permissions': userProfile['permissions'], // JSON string expected? Or list?
             // If local uses JSON string for permissions, ensure remote sends compatible format or convert
            'lastActive': DateTime.now().toString(),
            'is_synced': 1,
            'supabase_id': userProfile['id'], 
            'password': password // Optional: Cache password for offline? Security consideration. 
                                 // For now caching as per existing local auth pattern.
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
            // Run in background so it doesn't block UI immediately, 
            // but user will see data populate
            SupabaseService().pullRemoteData(); 
            
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('LoginWithSupabase Error: $e');
      return false;
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
      final createdUser = await _dbHelper.getUserByEmail(email);
      if (createdUser != null) {
        login(createdUser);
      }
      
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
