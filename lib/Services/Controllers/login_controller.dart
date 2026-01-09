import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/button_bar.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class LoginController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _authController = Get.put(AuthController());
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

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
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user != null && user['password'] == password) {
        _authController.login(user); // Store in global auth state
        Get.offAll(() => BottomNavigation());
      } else {
        Get.snackbar('Error', 'Invalid email or password',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
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