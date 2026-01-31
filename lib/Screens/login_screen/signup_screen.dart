import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/signup_controller.dart';
import 'package:pos/widgets/custom_button.dart';
import 'package:pos/widgets/custom_textfield.dart';
import 'package:pos/widgets/custom_loader.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side - Illustration/Branding (Hidden on mobile)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 1,
              child: Container(
                color: const Color.fromRGBO(30, 58, 138, 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.point_of_sale, size: 100, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Smart POS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Manage your business efficiently',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Right side - Signup Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mobile Logo (Visible only on small screens)
                      if (MediaQuery.of(context).size.width <= 800) ...[
                        const Icon(Icons.point_of_sale, size: 80, color: Color.fromRGBO(30, 58, 138, 1)),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Smart POS',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(30, 58, 138, 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign up to get started',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      CustomTextField(
                        controller: controller.nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: controller.emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      
                      Obx(() => CustomTextField(
                        controller: controller.passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: !controller.isPasswordVisible.value,
                        showEyeIcon: true,
                        onEyeTap: controller.togglePasswordVisibility,
                      )),
                      const SizedBox(height: 20),

                      Obx(() => CustomTextField(
                        controller: controller.confirmPasswordController,
                        hintText: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: !controller.isConfirmPasswordVisible.value,
                        showEyeIcon: true,
                        onEyeTap: controller.toggleConfirmPasswordVisibility,
                      )),
                      const SizedBox(height: 30),

                      Obx(() => controller.isLoading.value
                          ? const LoadingWidget()
                          : CustomButton(
                              text: 'Sign Up',
                              onPressed: controller.handleSignUp,
                            )),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
