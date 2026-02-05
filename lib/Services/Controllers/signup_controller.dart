import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pos/Screens/login_screen/login_screen.dart';

class SignUpController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();

  Future<void> handleSignUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields', 
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    if (password != confirm) {
      Get.snackbar('Error', 'Passwords do not match', 
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
        Get.snackbar('Error', 'Internet connection required for Sign Up', 
            backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
        return;
    }

    isLoading.value = true;

    try {
      print('=== DEBUG: Starting SignUp Process ===');
      print('Name: $name, Email: $email');
      
      // 1. SignUp via Supabase (Remote)
      print('DEBUG: Calling Supabase Remote SignUp...');
      final supabase = SupabaseService();
      final response = await supabase.signUp(email, password, name);
      
      print('DEBUG: Supabase Response Successful. User ID: ${response.user?.id}');
      print('DEBUG: Confirmation Email should be sent to: ${response.user?.email}');
      
      // 2. Create Local Account (Local)
      print('DEBUG: Creating Local Account in SQLite...');
      final success = await _authController.signUp(name, email, password, supabaseId: response.user?.id);
      
      print('DEBUG: Local SignUp Success: $success');
      
      if (success) {
        Get.snackbar(
          'Account Created', 
          'Your account has been created. Please log in to continue.', 
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP
        );
        Get.offAll(() => const LoginScreen());
      } else {
         Get.snackbar('Error', 'Account created remotely but failed locally (Email exists?)', 
             backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      print('=== DEBUG: SignUp FAILED ===');
      print('Error detail: $e');
      
      String errorMessage = 'Sign Up Failed: $e';
      if (e.toString().contains('already registered') || e.toString().contains('unique constraint')) {
        errorMessage = 'This email is already registered. Please login instead.';
      }
      
      Get.snackbar('Error', errorMessage, 
          backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
