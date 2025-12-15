import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/Services/Controllers/favourites_screen_controller.dart';
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
   
 
    final FavoritesController favoritesController = Get.put(FavoritesController(), permanent: true);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final cardSize = isTablet
        ? (isLandscape ? screenWidth / 6 : screenWidth / 4)
        : (isLandscape ? screenWidth / 5 : screenWidth / 3.5);

    final spacing = (screenWidth * 0.02).clamp(8.0, 16.0);

    final allQuickActions = [
      {'title': 'New Sale',        'icon': Icons.add_shopping_cart, 'color':Color(0xFF253746)},
      {'title': 'Inventory',       'icon': Icons.inventory,         'color':Color(0xFF253746)},
      {'title': 'Customers',       'icon': Icons.group,             'color':Color(0xFF253746)},
      {'title': 'Suppliers',       'icon': Icons.store,             'color':Color(0xFF253746)},
      {'title': 'Purchases',       'icon': Icons.shopping_bag,      'color':Color(0xFF253746)},
      {'title': 'Expenses',        'icon': Icons.money_off,         'color':Color(0xFF253746)},
      {'title': 'Sales Report',    'icon': Icons.bar_chart,         'color':Color(0xFF253746)},
      {'title': 'Stock Report',    'icon': Icons.inventory_2,       'color':Color(0xFF253746)},
      {'title': 'Analytics',       'icon': Icons.analytics,         'color':Color(0xFF253746)},
      {'title': 'Settings',        'icon': Icons.settings,          'color':Color(0xFF253746)},
      {'title': 'Backup & Restore','icon': Icons.cloud_upload,      'color':Color(0xFF253746)},
      {'title': 'Notifications',   'icon': Icons.notifications,     'color':Color(0xFF253746)},
      {'title': 'User Management', 'icon': Icons.supervisor_account,'color':Color(0xFF253746)},
      {'title': 'Loyalty Program', 'icon': Icons.card_giftcard,     'color':Color(0xFF253746)},
      {'title': 'Support',         'icon': Icons.headset_mic,       'color':Color(0xFF253746)},
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),

      // Beautiful Gradient AppBar – EXACTLY like ProfileScreen
     appBar: AppBar(
  elevation: 0,
  centerTitle: false,
  
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
  title: Text(
    'Favorites',
    style: TextStyle(
      fontSize: (isLargeScreen ? 24.0 : screenWidth * 0.05)
          .clamp(16.0, 26.0),
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Get.back(),
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
                    color: Color(0xFF11212D),
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
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final action = allQuickActions[index];
                final title = action['title'] as String;

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