import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/button_bar.dart';
class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isPasswordVisible = false.obs; // Track password visibility
  var isLoading = false.obs; // Track loading state

  // Basic email validation regex
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  // Simulate login with delay for loader
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validation checks
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (!isValidEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    // Show loader
    isLoading.value = true;

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Dummy credentials check
    if (email == 'test@example.com' && password == 'password123') {
      Get.offAll(() =>  BottomNavigation());
    } else {
      Get.snackbar(
        'Error',
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }

    // Hide loader
    isLoading.value = false;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}