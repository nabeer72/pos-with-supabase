import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/button_bar.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _authController = Get.put(AuthController());
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isPasswordVisible = false.obs;

  var isLoading = false.obs;
  
  final _supabaseService = SupabaseService();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }





  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please enter both email and password',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    
    try {
      // Check connectivity
      // Note: Connectivity check is good but sometimes unreliable (e.g. connected to wifi but no internet)
      // We can try remote login and catch exception to fallback
      bool loggedInStart = false;
      
      try {
         // Attempt Remote Login first
         final success = await _authController.loginWithSupabase(email, password);
         if (success) {
           loggedInStart = true;
           Get.offAll(() => BottomNavigation());
         }
      } catch (e) {
        print("Remote login failed or offline: $e");
      }

      if (!loggedInStart) {
        // Fallback to Local Login
        print("Attempting local login...");
        final user = await _dbHelper.getUserByEmail(email);
        
        if (user != null && user['password'] == password) {
          _authController.login(user); // Store in global auth state
          Get.offAll(() => BottomNavigation());
        } else {
          Get.snackbar('Error', 'Invalid email or password',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during login: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();

    super.onClose();
  }
}