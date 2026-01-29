import 'package:flutter/material.dart';
import 'package:pos/Screens/login_screen/login_screen.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/widgets/custom_button.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Screens/button_bar.dart'; // BottomNavigation
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthController authController = Get.find<AuthController>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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

          // Right side - Login Form
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

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 30),

                      CustomButton(
                        text: _isLoading ? 'Creating Account...' : 'Sign Up',
                        onPressed: _isLoading ? () {} : _handleSignUp,
                      ),
                      
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

  Future<void> _handleSignUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields', backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    if (password != confirm) {
      Get.snackbar('Error', 'Passwords do not match', backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
        Get.snackbar('Error', 'Internet connection required for Sign Up', backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
        return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. SignUp via Supabase (Remote)
      final supabase = SupabaseService();
      final response = await supabase.signUp(email, password);
      
      setState(() => _isLoading = false);

      // 2. Create Local Account (Local)
      final success = await authController.signUp(name, email, password);
      
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
         Get.snackbar('Error', 'Account created remotely but failed locally (Email exists?)', backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Sign Up Failed: $e', backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }
}
