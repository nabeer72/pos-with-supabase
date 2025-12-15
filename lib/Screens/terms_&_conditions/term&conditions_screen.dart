import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
  
    // Get screen width for responsive sizing
    final double screenWidth = MediaQuery.sizeOf(context).width;
    // Calculate responsive sizes based on screen width
    final double contentPadding = screenWidth * 0.05; // 5% of screen width for internal card padding

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),// Match HomeScreen background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(30, 58, 138, 1),
                Color.fromRGBO(59, 130, 246, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width for padding
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              // gradient: const LinearGradient(
              //   colors: [Color(0xFFE8F0FE), Color(0xFFF6F8FB)],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.grey[300]!.withOpacity(0.5)),
            ),
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                Text(
                  'By using this application, you agree to the following terms and conditions:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.black87.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                _buildTermItem(
                  context,
                  '1. Acceptance of Terms',
                  'You must comply with all terms and conditions outlined in this agreement. Continued use of the application constitutes acceptance of these terms.',
                ),
                _buildTermItem(
                  context,
                  '2. User Conduct',
                  'You agree not to use the application for any unlawful purpose or in any way that violates these terms. This includes not sharing inappropriate content or engaging in harmful activities.',
                ),
                _buildTermItem(
                  context,
                  '3. Account Responsibility',
                  'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                ),
                _buildTermItem(
                  context,
                  '4. Content Ownership',
                  'All content provided in the application, including courses and materials, is owned by the application or its licensors. You may not reproduce or distribute content without permission.',
                ),
                _buildTermItem(
                  context,
                  '5. Termination',
                  'We reserve the right to terminate or suspend your account at our discretion, without notice, for conduct that violates these terms or is harmful to other users.',
                ),
                _buildTermItem(
                  context,
                  '6. Updates to Terms',
                  'These terms may be updated periodically. You will be notified of significant changes, and continued use of the application constitutes acceptance of the updated terms.',
                ),
                SizedBox(height: screenWidth * 0.025),
                Text(
                  'For any questions, please contact our support team via the Help Center.',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.black87.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(BuildContext context, String title, String description) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            description,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.black87.withOpacity(0.8),
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}