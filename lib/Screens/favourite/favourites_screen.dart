import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/Services/Controllers/favourites_screen_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.deepOrangeAccent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize controller only if not already registered
    final FavoritesController favoritesController = Get.put(FavoritesController(), permanent: true);
    

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Calculate card size consistently with DashboardScreen
    final cardSize = isTablet
        ? (isLandscape ? screenWidth / 6 : screenWidth / 4)
        : (isLandscape ? screenWidth / 5 : screenWidth / 3.5);

    // Calculate spacing based on screen width
    final spacing = (screenWidth * 0.02).clamp(8.0, 16.0);

    final allQuickActions = [
      // 🛒 Business Modules
      {'title': 'New Sale', 'icon': Icons.add_shopping_cart, 'color': Colors.indigo[600]!},
      {'title': 'Inventory', 'icon': Icons.inventory, 'color': Colors.teal[400]!},
      {'title': 'Customers', 'icon': Icons.group, 'color': Colors.blue[400]!},
      {'title': 'Suppliers', 'icon': Icons.store, 'color': Colors.deepPurple[400]!},
      {'title': 'Purchases', 'icon': Icons.shopping_bag, 'color': Colors.orange[400]!},
      {'title': 'Expenses', 'icon': Icons.money_off, 'color': Colors.redAccent},
      // 📊 Reports & Analytics
      {'title': 'Sales Report', 'icon': Icons.bar_chart, 'color': Colors.purple[400]!},
      {'title': 'Stock Report', 'icon': Icons.inventory_2, 'color': Colors.amber[600]!},
      {'title': 'Analytics', 'icon': Icons.analytics, 'color': Colors.green[400]!},
      // ⚙️ System Tools
      {'title': 'Settings', 'icon': Icons.settings, 'color': Colors.grey[700]!},
      {'title': 'Backup & Restore', 'icon': Icons.cloud_upload, 'color': Colors.cyan[600]!},
      {'title': 'Notifications', 'icon': Icons.notifications, 'color': Colors.pinkAccent},
      {'title': 'User Management', 'icon': Icons.supervisor_account, 'color': Colors.blueGrey[600]!},
      {'title': 'Loyalty Program', 'icon': Icons.card_giftcard, 'color': Colors.deepOrangeAccent},
      {'title': 'Support', 'icon': Icons.headset_mic, 'color': Colors.brown[400]!},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Match DashboardScreen
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        title: Text(
          'Favorites',
          style: TextStyle(
            fontSize: (isLargeScreen ? 24.0 : screenWidth * 0.05).clamp(16.0, 26.0),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: (screenWidth * 0.05).clamp(16.0, 24.0),
          vertical: (screenHeight * 0.02).clamp(12.0, 20.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Favorites',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: allQuickActions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3),
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.0, // Ensure square cards
              ),
              itemBuilder: (context, index) {
                final action = allQuickActions[index];
                final title = action['title'] as String;
                // Wrap only the isFavorite check in Obx for minimal rebuilds
                return Obx(() {
                  final isFavorite = favoritesController.favoriteActions.contains(title);
                  return QuickActionCard(
                    title: title,
                    icon: action['icon'] as IconData,
                    color: action['color'] as Color,
                    cardSize: cardSize,
                    showFavorite: true,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () {
                      if (isFavorite) {
                        favoritesController.removeFavorite(title);
                      } else {
                        favoritesController.addFavorite(title);
                      }
                    },
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}