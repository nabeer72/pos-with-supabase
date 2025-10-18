import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/Services/Controllers/favourites_screen_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.deepOrangeAccent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final FavoritesController favoritesController = Get.put(FavoritesController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final cardSize = (screenWidth * (isLargeScreen ? 0.22 : isTablet ? 0.28 : 0.3)).clamp(100.0, 200.0);
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
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(
            fontSize: (isLargeScreen ? 24.0 : screenWidth * 0.05).clamp(16.0, 26.0),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: EdgeInsets.symmetric(
          horizontal: (screenWidth * 0.05).toDouble(),
          vertical: (screenHeight * 0.02).toDouble(),
        ),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Favorites',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 1.0,
                  children: allQuickActions.map((action) {
                    final title = action['title'] as String;
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
                  }).toList(),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
