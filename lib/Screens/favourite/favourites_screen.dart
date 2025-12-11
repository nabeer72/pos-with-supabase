import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/Services/Controllers/favourites_screen_controller.dart';

// Your original dark palette
class Palette {
  static const Color primary     = Color(0xFF06141B);
  static const Color primaryDark = Color(0xFF11212D);
  static const Color midDark     = Color(0xFF253746);
  static const Color midGray     = Color(0xFF4A5C6A);
  static const Color lightGray   = Color(0xFF9BA8AB);
  static const Color veryLight   = Color(0xFFCCD9CF);
  static const Color background  = Color(0xFFF8FAFC);
}

const Color accent = Color(0xFF00D4D4);

// Exact same gradient as ProfileScreen
const Color gradientStart = Color(0xFF1E3A8A); // Navy Blue
 const Color gradientEnd   = Color(0xFF3B82F6); // Soft Blue

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Status bar color match gradient start
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: gradientStart,
      statusBarIconBrightness: Brightness.light,
    ));

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
      {'title': 'New Sale',        'icon': Icons.add_shopping_cart, 'color': accent},
      {'title': 'Inventory',       'icon': Icons.inventory,         'color': Palette.midGray},
      {'title': 'Customers',       'icon': Icons.group,             'color': Palette.lightGray},
      {'title': 'Suppliers',       'icon': Icons.store,             'color': Palette.midDark},
      {'title': 'Purchases',       'icon': Icons.shopping_bag,      'color': Palette.primaryDark},
      {'title': 'Expenses',        'icon': Icons.money_off,         'color': Colors.redAccent},
      {'title': 'Sales Report',    'icon': Icons.bar_chart,         'color': accent},
      {'title': 'Stock Report',    'icon': Icons.inventory_2,       'color': Palette.midGray},
      {'title': 'Analytics',       'icon': Icons.analytics,         'color': Palette.lightGray},
      {'title': 'Settings',        'icon': Icons.settings,          'color': Palette.midDark},
      {'title': 'Backup & Restore','icon': Icons.cloud_upload,      'color': accent},
      {'title': 'Notifications',   'icon': Icons.notifications,     'color': Palette.lightGray},
      {'title': 'User Management', 'icon': Icons.supervisor_account,'color': Palette.midGray},
      {'title': 'Loyalty Program', 'icon': Icons.card_giftcard,     'color': accent},
      {'title': 'Support',         'icon': Icons.headset_mic,       'color': Palette.midDark},
    ];

    return Scaffold(
      backgroundColor: Palette.background,

      // Beautiful Gradient AppBar – EXACTLY like ProfileScreen
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
            centerTitle: false,
            title: Text(
              'Favorites',
              style: TextStyle(
                fontSize: (isLargeScreen ? 24.0 : screenWidth * 0.05).clamp(16.0, 26.0),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
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
                    color: Palette.primaryDark,
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