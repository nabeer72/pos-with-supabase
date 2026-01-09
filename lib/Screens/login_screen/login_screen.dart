import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/login_controller.dart';
import 'package:pos/widgets/custom_button.dart';
import 'package:pos/widgets/custom_loader.dart';
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
                  onPressed: loginController.login,
                )),

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
);

  }
}