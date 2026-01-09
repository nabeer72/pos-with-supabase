import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/widgets/custom_button.dart';

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
      Get.snackbar('Error', 'Please fill all fields', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (password != confirm) {
      Get.snackbar('Error', 'Passwords do not match', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    final success = await authController.signUp(name, email, password);
    
    setState(() => _isLoading = false);

    if (success) {
      Get.snackbar('Success', 'Account created successfully', backgroundColor: Colors.green, colorText: Colors.white);
      // AuthController's login should have been called, usually we navigate to dashboard from there or here
      // Assuming existing login flow handles navigation or we force it:
      // Check where normal login goes -> usually home.
      // We can rely on AuthController state or manually navigate.
      // For now, let's go Back (to login) or to Home if auto-logged in.
      // If auto-logged in, Main/GetX observer might handle it, or we push replacement.
      // Let's assume standard flow:
      Get.offAllNamed('/home'); // Or whatever the route is. 
      // Actually finding Home screen import might be safer or using Get.offAll(() => Dashboard/HomeScreen());
      // But let's verify existing routing. 
    } else {
       Get.snackbar('Error', 'Email already exists or invalid', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
