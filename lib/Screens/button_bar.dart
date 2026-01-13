import 'package:flutter/material.dart';
import 'package:pos/Screens/dashboard/home_screen.dart';
import 'package:pos/Screens/favourite/favourites_screen.dart';
import 'package:pos/Screens/profile/profile_screen.dart';
import 'package:pos/Screens/report/report_screen.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  // List of screens to navigate between
  List<Widget> get _screens {
    final isAdmin = Get.find<AuthController>().isAdmin;
    return [
      DashboardScreen(),
      ReportScreen(),
      if (isAdmin) FavoritesScreen(),
      ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: fontSize,
        unselectedFontSize: fontSize,
        iconSize: iconSize,
        showUnselectedLabels: !isSmallScreen, // Hide labels on small screens
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          if (Get.find<AuthController>().isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
