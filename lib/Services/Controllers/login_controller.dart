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
      bool loggedInStart = false;
      
      try {
         // Attempt Remote Login first
         await _authController.loginWithSupabase(email, password);
         loggedInStart = true;
         // If successful, navigate
         Get.offAll(() => BottomNavigation());
      } on AuthException catch (e) {
         print("Supabase Auth Exception: ${e.message}");
         
         // CRITICAL FIX: If email is not confirmed, we MUST tell the user and STOP.
         if (e.message.contains("Email not confirmed")) {
           Get.snackbar('Verification Required', 'Please check your email to confirm your account before logging in.',
               snackPosition: SnackPosition.BOTTOM, 
               backgroundColor: Colors.orange, 
               colorText: Colors.white,
               duration: const Duration(seconds: 5));
           isLoading.value = false;
           return; 
         }

         // For other auth errors (e.g. invalid credentials), we might fall back to local 
         // ONLY IF we think the user might be offline or using old credentials. 
         // But if Supabase explicitly says "Invalid login credentials", local won't help if it's empty.
         // However, following original pattern: fall back to local in case of "failure".
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
           // If local also fails, show generic error OR specific error if we had one from Supabase?
           // The user gets "Invalid email or password" which is correct if local is also missing.
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