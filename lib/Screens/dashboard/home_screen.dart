import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/customers/customer_screen.dart';
import 'package:pos/Screens/dashboard/inventory/inventory_screen.dart';
import 'package:pos/Screens/expenses/expenses_screen.dart';
import 'package:pos/Screens/newSales/new_sales_screen.dart';
import 'package:pos/Screens/notification/notification_screen.dart';
import 'package:pos/Screens/report/report_screen.dart';
import 'package:pos/Screens/suppliers/suppliers_screen.dart';
import 'package:pos/Screens/userManagement/user_management.dart';
import 'package:pos/Services/Controllers/favourites_screen_controller.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/sales_card.dart';
import 'package:pos/widgets/search_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesController favoritesController = Get.put(FavoritesController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    // ignore: unused_local_variable
    final isLargeScreen = screenWidth > 900;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Calculate card size based on screen width and orientation
    final cardSize = isTablet
        ? (isLandscape ? screenWidth / 6 : screenWidth / 4) // Adjust for landscape
        : (isLandscape ? screenWidth / 5 : screenWidth / 3.5);

    final salesData = {
      'amount': 4250.75,
      'transactionCount': 89,
    };

    final allQuickActions = [
      {'title': 'New Sale', 'icon': Icons.add_shopping_cart, 'color': Colors.indigo},
      {'title': 'Inventory', 'icon': Icons.inventory, 'color': Colors.teal},
      {'title': 'Customers', 'icon': Icons.group, 'color': Colors.blue},
      {'title': 'Suppliers', 'icon': Icons.store, 'color': Colors.deepPurple},
      {'title': 'Purchases', 'icon': Icons.shopping_bag, 'color': Colors.orange},
      {'title': 'Expenses', 'icon': Icons.money_off, 'color': Colors.redAccent},
      {'title': 'Sales Report', 'icon': Icons.bar_chart, 'color': Colors.purple},
      {'title': 'Stock Report', 'icon': Icons.inventory_2, 'color': Colors.amber},
      {'title': 'Analytics', 'icon': Icons.analytics, 'color': Colors.green},
      {'title': 'Settings', 'icon': Icons.settings, 'color': Colors.grey},
      {'title': 'Backup & Restore', 'icon': Icons.cloud_upload, 'color': Colors.cyan},
      {'title': 'Notifications', 'icon': Icons.notifications, 'color': Colors.pinkAccent},
      {'title': 'User Management', 'icon': Icons.supervisor_account, 'color': Colors.blueGrey},
      {'title': 'Loyalty Program', 'icon': Icons.card_giftcard, 'color': Colors.deepOrangeAccent},
      {'title': 'Support', 'icon': Icons.headset_mic, 'color': Colors.brown},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Get.to(() =>  NotificationScreen());
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepOrangeAccent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔍 Search Bar
            SearchBarWidget(),

            const SizedBox(height: 20),

            /// 💰 Sales Summary
            SalesAndTransactionsWidget(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              salesData: salesData,
            ),

            const SizedBox(height: 24),

            /// ⚡ Quick Actions Header
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
              ],
            ),

            const SizedBox(height: 12),

            /// Quick Actions Grid or Empty State
            Obx(() {
              final favoriteActions = allQuickActions
                  .where((action) => favoritesController.favoriteActions.contains(action['title']))
                  .toList();

              if (favoriteActions.isEmpty) {
                // 🟢 Show Empty State if No Favorites
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 130),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "No favorite actions yet",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show Favorite Actions in Grid
              return GridView.builder(
                itemCount: favoriteActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1, // Ensure square cards
                ),
                itemBuilder: (context, index) {
                  final action = favoriteActions[index];
                  return QuickActionCard(
                    title: action['title'] as String,
                    icon: action['icon'] as IconData,
                    color: action['color'] as Color,
                    cardSize: cardSize, // Use calculated card size
                    onTap: () {
                      switch (action['title']) {
                        case 'New Sale':
                          Get.to(() => const NewSaleScreen());
                          break;
                        case 'Inventory':
                          Get.to(() => const InventoryScreen());
                          break;
                        case 'Sales Report':
                          Get.to(() => const ReportScreen());
                          break;
                        case 'Customers':
                          Get.to(() => const AddCustomerScreen());
                          break;
                        case 'Settings':
                          Get.toNamed('/settings');
                          break;
                        case 'Analytics':
                          Get.to(() =>  ReportScreen());
                          break;
                        case 'Expenses':
                          Get.to(() =>  ExpensesScreen());
                          break;
                        case 'Notifications':
                          Get.to(() =>  NotificationScreen());
                          break;
                        case 'Suppliers':
                          Get.to(() =>  SuppliersScreen());
                          break;
                        case 'User Management':
                          Get.to(() =>  UserManagementScreen());
                          break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${action['title']} feature coming soon!",
                              ),
                            ),
                          );
                      }
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}