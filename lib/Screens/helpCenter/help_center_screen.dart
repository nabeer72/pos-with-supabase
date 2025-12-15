import 'package:flutter/material.dart';

import 'package:pos/widgets/collapseable.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  // Exact same colors as ProfileScreen
  static const Color accentColor = Colors.grey;
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // Reusable card decoration (identical to ProfileScreen)
  BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    final double padding = (screenWidth * 0.05).clamp(16.0, 24.0);
    final double iconSize = (screenWidth * 0.06).clamp(22.0, 28.0);
    final double titleFont = isTablet ? 18.0 : 16.0;
    final double bodyFont = isTablet ? 15.0 : 14.0;

    return Scaffold(
      backgroundColor: backgroundColor,
        appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Help Center',
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
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            // FAQ
            CollapsibleCardWidget(
              id: 'faq',
              title: 'Frequently Asked Questions',
              leadingIcon: Icon(Icons.question_answer, color: accentColor, size: iconSize),
              accent: accentColor,
              expandedChildren: [
                _buildQA("How do I reset my password?",
                    "Go to Login → Tap 'Forgot Password' → Enter your email → Follow the reset link."),
                const SizedBox(height: 16),
                _buildQA("How to update my profile?",
                    "Go to Profile screen → Tap on any field or the edit button to modify your information."),
                const SizedBox(height: 16),
                _buildQA("Where can I see my orders?",
                    "Use the 'Orders' tab in the bottom navigation bar."),
              ],
            ),

            const SizedBox(height: 20),

            // Contact Support
            CollapsibleCardWidget(
              id: 'contact',
              title: 'Contact Support',
              leadingIcon: Icon(Icons.contact_support, color: accentColor, size: iconSize),
              accent: accentColor,
              expandedChildren: [
                _buildContactRow(Icons.email, "support@yourapp.com"),
                const SizedBox(height: 12),
                _buildContactRow(Icons.phone, "+1 (800) 123-4567"),
                const SizedBox(height: 12),
                _buildContactRow(Icons.access_time, "Mon–Fri: 9:00 AM – 6:00 PM"),
              ],
            ),

            const SizedBox(height: 20),

            // Resources
            CollapsibleCardWidget(
              id: 'resources',
              title: 'Help Resources',
              leadingIcon: Icon(Icons.menu_book, color: accentColor, size: iconSize),
              accent: accentColor,
              expandedChildren: [
                const Text(
                  "Browse detailed guides and video tutorials:",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.link, color: accentColor, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      "www.yourapp.com/help",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Support Hours Card (Non-collapsible)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: cardDecoration,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.access_time_filled, color: accentColor, size: 28),
                    title: Text("Support Hours", style: TextStyle(color: Colors.grey[600], fontSize: bodyFont)),
                    subtitle: Text(
                      "Monday – Friday\n9:00 AM – 6:00 PM",
                      style: TextStyle(color: Colors.black87, fontSize: titleFont, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: Icon(Icons.phone_in_talk, color: accentColor, size: 28),
                    title: Text("Emergency Hotline", style: TextStyle(color: Colors.grey[600], fontSize: bodyFont)),
                    subtitle: Text(
                      "+1 (800) 123-4567\nAvailable 24/7",
                      style: TextStyle(color: Colors.black87, fontSize: titleFont, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Reusable Q&A block
  Widget _buildQA(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          answer,
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      ],
    );
  }

  // Reusable contact row
  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}