import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/button_bar.dart';
import 'package:pos/Screens/terms_&_conditions/term&conditions_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Colors.grey;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAll(() =>  BottomNavigation()),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              padding: EdgeInsets.all((screenWidth * 0.05).clamp(12.0, 20.0)),
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Profile Details Card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                      margin: EdgeInsets.only(top: cardTopMargin),
                      child: Column(
                        children: [
                          SizedBox(height: spacerHeight),
                          ListTile(
                            leading: Icon(
                              Icons.person,
                              color: accent,
                              size: (screenWidth * 0.06).clamp(20.0, 24.0),
                            ),
                            subtitle: Text(
                              'Nabeer Hussain',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet
                                    ? (screenWidth * 0.04).clamp(15.0, 17.0)
                                    : (screenWidth * 0.035).clamp(13.0, 15.0),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                          ListTile(
                            leading: Icon(
                              Icons.email,
                              color: accent,
                              size: (screenWidth * 0.06).clamp(20.0, 24.0),
                            ),
                            subtitle: Text(
                              'nabeerhussain@72gmail.com',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet
                                    ? (screenWidth * 0.04).clamp(15.0, 17.0)
                                    : (screenWidth * 0.035).clamp(13.0, 15.0),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                          ListTile(
                            leading: Icon(
                              Icons.phone,
                              color: accent,
                              size: (screenWidth * 0.06).clamp(20.0, 24.0),
                            ),
                            subtitle: Text(
                              '+1 234 567 8900',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet
                                    ? (screenWidth * 0.04).clamp(15.0, 17.0)
                                    : (screenWidth * 0.035).clamp(13.0, 15.0),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                          ListTile(
                            leading: Icon(
                              Icons.badge,
                              color: accent,
                              size: (screenWidth * 0.06).clamp(20.0, 24.0),
                            ),
                            subtitle: Text(
                              '12345-6789012-3',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet
                                    ? (screenWidth * 0.04).clamp(15.0, 17.0)
                                    : (screenWidth * 0.035).clamp(13.0, 15.0),
                              ),
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                          ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: accent,
                              size: (screenWidth * 0.06).clamp(20.0, 24.0),
                            ),
                            subtitle: Text(
                              '123 Main St, City, Country',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet
                                    ? (screenWidth * 0.04).clamp(15.0, 17.0)
                                    : (screenWidth * 0.035).clamp(13.0, 15.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar
                    Positioned(
                      top: avatarTopPosition,
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: const AssetImage('assets/profile.jpeg'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (screenWidth * 0.05).clamp(12.0, 20.0)),
                // Settings Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.description,
                          color: accent,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                        title: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: isTablet
                                ? (screenWidth * 0.045).clamp(17.0, 19.0)
                                : (screenWidth * 0.04).clamp(15.0, 17.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: accent,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                        onTap: () {
                          Get.to(() => const TermsAndConditionsScreen());
                        },
                      ),
                      Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                      ListTile(
                        leading: Icon(
                          Icons.help,
                          color: accent,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                        title: Text(
                          'Help Center',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: isTablet
                                ? (screenWidth * 0.045).clamp(17.0, 19.0)
                                : (screenWidth * 0.04).clamp(15.0, 17.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: accent,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                        onTap: () {
                          // Get.to(() => const HelpCenterScreen());
                        },
                      ),
                      Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: accent,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: isTablet
                                ? (screenWidth * 0.045).clamp(17.0, 19.0)
                                : (screenWidth * 0.04).clamp(15.0, 17.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: accent,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
                        onTap: () {
                          _showLogoutDialog(context, accent, screenWidth);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, Color accent, double screenWidth) {
    Get.defaultDialog(
      title: 'Logout',
      titleStyle: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: (screenWidth * 0.05).clamp(18.0, 22.0),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: TextStyle(
          fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.05).clamp(16.0, 24.0),
        vertical: (screenWidth * 0.03).clamp(12.0, 16.0),
      ),
      confirm: TextButton(
        onPressed: () {
          Get.back();
          Get.snackbar('Logged Out', 'You have been logged out successfully');
          // Example: Get.offAll(() => const LoginScreen());
        },
        style: TextButton.styleFrom(foregroundColor: accent),
        child: Text(
          'Yes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
          ),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        child: Text(
          'No',
          style: TextStyle(
            fontSize: (screenWidth * 0.04).clamp(14.0, 16.0),
          ),
        ),
      ),
    );
  }
}