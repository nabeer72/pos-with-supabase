import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/login_controller.dart';
import 'package:pos/widgets/custom_button.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/widgets/custom_textfield.dart';
import 'package:pos/Screens/login_screen/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final loginController = Get.put(LoginController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Powered by SATA TECHNOLOGIES',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.05,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  GestureDetector(
                    onLongPress: () async {
                      // Hidden feature to reset database for testing/Admin removal
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset Application?'),
                          content: const Text('This will delete ALL data including users. You will need to sign up again.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reset', style: TextStyle(color: Colors.red))
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await DatabaseHelper().clearAllData();
                        Get.snackbar('Success', 'App data cleared. Please restart or sign up.', snackPosition: SnackPosition.TOP);
                      }
                    },
                    child: Icon(
                      Icons.store_mall_directory,
                      size: screenWidth * 0.2,
                      color: const Color.fromRGBO(59, 130, 246, 1),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // Added SizedBox for spacing after the icon
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  CustomTextField(
                    controller: loginController.emailController,
                    hintText: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Obx(() => CustomTextField(
                        controller: loginController.passwordController,
                        hintText: 'Password',
                        icon: Icons.lock,
                        obscureText: !loginController.isPasswordVisible.value,
                        showEyeIcon: true,
                        onEyeTap: loginController.togglePasswordVisibility,
                      )),
                  SizedBox(height: screenHeight * 0.04),
                  Obx(() => loginController.isLoading.value
                      ? const LoadingWidget()
                      : CustomButton(
                          text: 'Login',
                          onPressed: () {
                            loginController.login();
                          })),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Get.to(() => const SignUpScreen()),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}