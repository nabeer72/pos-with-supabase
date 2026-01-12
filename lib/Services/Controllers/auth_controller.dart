import 'package:get/get.dart';
import 'dart:convert';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';

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
  }

  void logout() async {
    isLoggedIn.value = false;
    currentUser.value = {};
    userPermissions.value = [];
    try {
      await SupabaseService().signOut();
    } catch(e) {
      print("Error signing out from supabase: $e");
    }
  }

  bool hasPermission(String permission) {
    if (userPermissions.contains('all')) return true;
    return userPermissions.contains(permission);
  }

  String get userRole => currentUser['role'] ?? 'Guest';
  String get userName => currentUser['name'] ?? 'Unknown';

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
        'role': 'Cashier', // Default role
        'lastActive': DateTime.now().toString(),
        'permissions': jsonEncode(['sales', 'customers']), // Default permissions
        'is_synced': 0, // Flag for sync
      };

      await _dbHelper.insertUser(newUser);
      
      // Auto login after signup
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
}
