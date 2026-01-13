import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/button_bar.dart';
import 'package:pos/Screens/helpCenter/help_center_screen.dart';
import 'package:pos/Screens/terms_&_conditions/term&conditions_screen.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Screens/login_screen/login_screen.dart';
import 'package:pos/Screens/userManagement/user_management.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // AppBar gradient (reused for avatar border)
  static const Color gradientStart = Color(0xFF1E3A8A); // Navy Blue
  static const Color gradientEnd   = Color(0xFF3B82F6); // Soft Blue
  static const Color accent = Color(0xFF253746); // Slate Grey

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final double avatarRadius = (isLandscape ? screenHeight : screenWidth) * 0.1;
    final double cardTopMargin = avatarRadius * (isLandscape ? 2.0 : 2.5);
    final double avatarTopPosition = avatarRadius * (isLandscape ? 1.2 : 1.5);
    final double spacerHeight = avatarRadius;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.offAll(() => BottomNavigation()),
            ),
            title: Text(
              'Profile',
              style: TextStyle(
                fontSize: (isLargeScreen ? 24.0 : screenWidth * 0.05).clamp(16.0, 26.0),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all((screenWidth * 0.05).clamp(12.0, 20.0)),
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // MAIN PROFILE CARD (unchanged – white with light border)
                Container(
                  margin: EdgeInsets.only(top: cardTopMargin),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Obx(() {
                    final user = Get.find<AuthController>().currentUser;
                    return Column(
                      children: [
                        SizedBox(height: spacerHeight),
                        _profileTile(
                          icon: Icons.person,
                          title: user['name'] ?? 'Guest User',
                          accent: accent,
                          screenWidth: screenWidth,
                          isTablet: isTablet
                        ),
                        _divider(),
                        _profileTile(
                          icon: Icons.email_outlined,
                          title: user['email'] ?? 'No Email',
                          accent: accent,
                          screenWidth: screenWidth,
                          isTablet: isTablet
                        ),
                        _divider(),
                        _profileTile(
                          icon: Icons.workspace_premium, // Changed icon for Role
                          title: user['role'] ?? 'Cashier',
                          accent: accent,
                          screenWidth: screenWidth,
                          isTablet: isTablet
                        ),
                        _divider(),
                        _profileTile(
                          icon: Icons.category, // Changed icon for Permissions length or similar? Or just keep it simpler
                          title: 'Permissions: ${(Get.find<AuthController>().userPermissions.length)}',
                          accent: accent,
                          screenWidth: screenWidth,
                          isTablet: isTablet
                        ),
                        _divider(),
                        _profileTile(
                          icon: Icons.access_time, // Last Active
                          title: 'Last Active: ${user['lastActive'] != null ? user['lastActive'].toString().split(' ')[0] : 'Now'}',
                          accent: accent,
                          screenWidth: screenWidth,
                          isTablet: isTablet
                        ),
                      ],
                    );
                  }),
                ),

                // AVATAR WITH GRADIENT BORDER (exactly like AppBar)
                Positioned(
                  top: avatarTopPosition,
                  child: Container(
                    padding: const EdgeInsets.all(4), // border thickness
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [gradientStart, gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: const AssetImage('assets/profile.jpeg'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: (screenWidth * 0.05).clamp(12.0, 20.0)),

            // SETTINGS CARD (unchanged – white with light border)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    onTap: () => Get.to(() => const TermsAndConditionsScreen()),
                    accent: accent,
                    screenWidth: screenWidth,
                    isTablet: isTablet,
                  ),
                  _divider(),
                  if (Get.find<AuthController>().isAdmin) ...[
                    _settingsTile(
                      icon: Icons.people,
                      title: 'User Management',
                      onTap: () => Get.to(() => UserManagementScreen()),
                      accent: accent,
                      screenWidth: screenWidth,
                      isTablet: isTablet,
                    ),
                    _divider(),
                  ],
                  _settingsTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () => Get.to(() => const HelpCenterScreen()),
                    accent: accent,
                    screenWidth: screenWidth,
                    isTablet: isTablet,
                  ),
                  _divider(),
                  _settingsTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () => _showLogoutDialog(context, screenWidth),
                    accent: Colors.redAccent,
                    screenWidth: screenWidth,
                    isTablet: isTablet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All your original tile/divider/dialog widgets – 100% unchanged
  Widget _profileTile({
    required IconData icon,
    required String title,
    required Color accent,
    required double screenWidth,
    required bool isTablet,
  }) {
    return ListTile(
      leading: Icon(icon, color: accent, size: (screenWidth * 0.06).clamp(20.0, 24.0)),
      subtitle: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: isTablet ? (screenWidth * 0.04).clamp(15.0, 17.0) : (screenWidth * 0.035).clamp(13.0, 15.0),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color accent,
    required double screenWidth,
    required bool isTablet,
  }) {
    return ListTile(
      leading: Icon(icon, color: accent, size: (screenWidth * 0.06).clamp(22.0, 26.0)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? (screenWidth * 0.045).clamp(17.0, 19.0) : (screenWidth * 0.04).clamp(15.0, 17.0),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: accent, size: (screenWidth * 0.06).clamp(22.0, 26.0)),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFE2E8F0));

  void _showLogoutDialog(BuildContext context, double screenWidth) {
    Get.defaultDialog(
      backgroundColor: Colors.white,
      title: "Logout",
      titleStyle: TextStyle(fontSize: (screenWidth * 0.05).clamp(18.0, 22.0), fontWeight: FontWeight.bold),
      middleText: "Are you sure you want to logout?",
      confirm: TextButton(
        onPressed: () {
          Get.back(); // Close dialog
          Get.find<AuthController>().logout(); // Perform logout
          Get.offAll(() => const LoginScreen()); // Navigate to login
        },
        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        child: const Text("Yes"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("No")),
    );
  }
}