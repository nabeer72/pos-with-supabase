import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/button_bar.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const accent =  Colors.grey;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double avatarRadius = screenWidth * 0.12;
    final double cardTopMargin = avatarRadius * 2.5;
    final double avatarTopPosition = avatarRadius * 1.5;
    final double spacerHeight = avatarRadius;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor:  Colors.deepOrangeAccent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAll(() => BottomNavigation()),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(screenWidth * 0.04),
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
                      leading: Icon(Icons.person, color: accent, size: 24),
                      subtitle: Text(
                        'John Doe',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Divider(
                        height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                    ListTile(
                      leading: Icon(Icons.email, color: accent, size: 24),
                      subtitle: Text(
                        'john.doe@example.com',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Divider(
                        height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                    ListTile(
                      leading: Icon(Icons.phone, color: accent, size: 24),
                      subtitle: Text(
                        '+1 234 567 8900',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Divider(
                        height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                    ListTile(
                      leading: Icon(Icons.badge, color: accent, size: 24),
                      subtitle: Text(
                        '12345-6789012-3',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Divider(
                        height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                    ListTile(
                      leading: Icon(Icons.location_on, color: accent, size: 24),
                      subtitle: Text(
                        '123 Main St, City, Country',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Divider(
                    //     height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                    // ListTile(
                    //   leading: Icon(Icons.edit, color: accent, size: 24),
                    //   title: Text(
                    //     'Edit Profile',
                    //     style: TextStyle(
                    //       color: Colors.black87,
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    //   trailing:
                    //       Icon(Icons.chevron_right, color: accent, size: 24),
                    //   onTap: () {
                    //     // Get.to(() => EditProfileScreen());
                    //   },
                    // ),
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
          SizedBox(height: screenWidth * 0.04),
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
                  leading: Icon(Icons.description, color: accent, size: 24),
                  title: Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: accent, size: 24),
                  onTap: () {
                    // Get.to(() => TermsAndConditionsScreen());
                  },
                ),
                Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.help, color: accent, size: 24),
                  title: Text(
                    'Help Center',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: accent, size: 24),
                  onTap: () {
                    // Get.to(() => HelpCenterScreen());
                  },
                ),
                Divider(height: 1, color: Colors.grey[300]!.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.logout, color: accent, size: 24),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: accent, size: 24),
                  onTap: () {
                    _showLogoutDialog(context, accent);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, Color accent) {
    Get.defaultDialog(
      title: 'Logout',
      titleStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      content: const Text(
        'Are you sure you want to logout?',
        style: TextStyle(fontSize: 16),
      ),
      confirm: TextButton(
        onPressed: () {
          // Add logout logic here (clear session, navigate to login)
          Get.back();
          Get.snackbar('Logged Out', 'You have been logged out successfully');
          // Example: Get.offAll(() => LoginScreen());
        },
        style: TextButton.styleFrom(foregroundColor: accent),
        child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        child: const Text('No'),
      ),
    );
  }
}
