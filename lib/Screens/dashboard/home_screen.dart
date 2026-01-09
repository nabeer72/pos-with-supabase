import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Screens/customers/customer_screen.dart';
import 'package:pos/Screens/dashboard/inventory/inventory_screen.dart';
import 'package:pos/Screens/expenses/expenses_screen.dart';
import 'package:pos/Screens/newSales/new_sales_screen.dart';
import 'package:pos/Screens/notification/notification_screen.dart';
import 'package:pos/Screens/report/report_screen.dart';
import 'package:pos/Screens/suppliers/suppliers_screen.dart';
import 'package:pos/Screens/userManagement/user_management.dart';
import 'package:pos/Screens/helpCenter/help_center_screen.dart';
import 'package:pos/Services/Controllers/favourites_screen_controller.dart';
import 'package:pos/Services/Controllers/dashboard_controller.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Screens/favourite/favourites_screen.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/sales_card.dart';
import 'package:pos/Screens/dashboard/backup_screen.dart';
import 'package:pos/Screens/login_screen/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboardController = Get.put(DashboardController());
    final AuthController authController = Get.find<AuthController>();
    final FavoritesController favoritesController = Get.put(FavoritesController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final cardSize = isTablet
        ? (isLandscape ? screenWidth / 6 : screenWidth / 4)
        : (isLandscape ? screenWidth / 5 : screenWidth / 3.5);

    final allQuickActions = [
      {'title': 'New Sale', 'icon': Icons.add_shopping_cart, 'permission': 'sales'},
      {'title': 'Inventory', 'icon': Icons.inventory, 'permission': 'inventory'},
      {'title': 'Customers', 'icon': Icons.person, 'permission': 'customers'},
      {'title': 'Suppliers', 'icon': Icons.local_shipping, 'permission': 'suppliers'},
      {'title': 'Expenses', 'icon': Icons.money_off, 'permission': 'expenses'},
      {'title': 'Sales Report', 'icon': Icons.bar_chart, 'permission': 'reports'},
      {'title': 'User Management', 'icon': Icons.people, 'permission': 'users'},
      {'title': 'Settings', 'icon': Icons.settings, 'permission': 'settings'},
      {'title': 'Backup & Restore', 'icon': Icons.cloud_upload, 'permission': 'backup'},
      {'title': 'Analytics', 'icon': Icons.insights, 'permission': 'analytics'},
      {'title': 'Purchases', 'icon': Icons.shopping_bag, 'permission': 'purchases'},
      {'title': 'Stock Report', 'icon': Icons.assignment_turned_in, 'permission': 'inventory'},
      {'title': 'Loyalty Program', 'icon': Icons.card_giftcard, 'permission': 'loyalty'},
      {'title': 'Support', 'icon': Icons.help_center, 'permission': 'support'},
    ];

    final filteredActions = allQuickActions.where((action) {
      return authController.hasPermission(action['permission'] as String);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: const Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                Get.to(() => NotificationScreen());
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                authController.logout();
                Get.offAll(() => const LoginScreen());
              },
            ),
          ],
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Obx(() => SalesAndTransactionsWidget(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              salesData: {
                'amount': dashboardController.salesSummary['totalAmount'] ?? 0.0,
                'transactionCount': dashboardController.salesSummary['totalCount'] ?? 0,
              },
            )),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quick Actions",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                TextButton(
                  onPressed: () => Get.to(() => const FavoritesScreen()),
                  child: const Text('Manage', style: TextStyle(color: Color.fromRGBO(59, 130, 246, 1))),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Obx(() {
              final favoriteActions = filteredActions
                  .where((action) => favoritesController.favoriteActions
                      .contains(action['title']))
                  .toList();

              if (favoriteActions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.star_border, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No favorites added yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () => Get.to(() => const FavoritesScreen()),
                          child: const Text('Add your first favorite'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: favoriteActions.length,
                itemBuilder: (context, index) {
                  final action = favoriteActions[index];
                  return QuickActionCard(
                    title: action['title'] as String,
                    icon: action['icon'] as IconData,
                    color: const Color(0xFF253746),
                    cardSize: cardSize,
                    onTap: () => _handleAction(context, action['title'] as String),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String title) {
    switch (title) {
      case 'New Sale':
        Get.to(() => const NewSaleScreen());
        break;
      case 'Inventory':
        Get.to(() => InventoryScreen());
        break;
      case 'Sales Report':
        Get.to(() => const ReportScreen());
        break;
      case 'Customers':
        Get.to(() => const AddCustomerScreen());
        break;
      case 'Expenses':
        Get.to(() => ExpensesScreen());
        break;
      case 'Notifications':
        Get.to(() => NotificationScreen());
        break;
      case 'Suppliers':
        Get.to(() => SuppliersScreen());
        break;
      case 'Support':
        Get.to(() => const HelpCenterScreen());
        break;
      case 'User Management':
        Get.to(() => UserManagementScreen());
        break;
      case 'Backup & Restore':
        Get.to(() => const BackupScreen());
        break;
      case 'Settings':
        Get.to(() => const SettingsScreen());
        break;
      case 'Analytics':
        Get.to(() => const AnalyticsScreen());
        break;
      case 'Purchases':
        Get.to(() => const PurchasesScreen());
        break;
      case 'Stock Report':
        Get.to(() => const StockReportScreen());
        break;
      case 'Loyalty Program':
        Get.to(() => const LoyaltyProgramScreen());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$title coming soon!")),
        );
    }
  }
}

// Simple Placeholder Screens to "Enable" features
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Database Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Reset All Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('This will permanently delete all products, sales, customers, and expenses.'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
            onTap: () => _showResetConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text('Are you sure? This action is irreversible and will wipe all your business data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper().clearAllData();
              Get.snackbar(
                'Database Wiped',
                'All data has been successfully cleared.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              // Refresh app state if needed
              Get.find<DashboardController>().fetchDashboardData(); 
              Get.offAll(() => const DashboardScreen());
            },
            child: const Text('Reset Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics', style: TextStyle(color: Colors.white)), backgroundColor: Colors.indigo[900]),
      body: const Center(child: Text('Analytics Screen - Deep dive into your sales trends.')),
    );
  }
}

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal[900]),
      body: const Center(child: Text('Purchases Screen - Manage your inventory acquisitions.')),
    );
  }
}

class StockReportScreen extends StatelessWidget {
  const StockReportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Report', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green[900]),
      body: const Center(child: Text('Stock Report - Real-time inventory status.')),
    );
  }
}

class LoyaltyProgramScreen extends StatelessWidget {
  const LoyaltyProgramScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Program', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange[900]),
      body: const Center(child: Text('Loyalty Program - Reward your best customers.')),
    );
  }
}