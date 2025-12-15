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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesController favoritesController = Get.put(FavoritesController());

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final cardSize = isTablet
        ? (isLandscape ? screenWidth / 6 : screenWidth / 4)
        : (isLandscape ? screenWidth / 5 : screenWidth / 3.5);

    final salesData = {
      'amount': 4250.75,
      'transactionCount': 89,
    };

    final allQuickActions = [
      {'title': 'New Sale', 'icon': Icons.add_shopping_cart},
      {'title': 'Inventory', 'icon': Icons.inventory},
      {'title': 'Customers', 'icon': Icons.group},
      {'title': 'Suppliers', 'icon': Icons.store},
      {'title': 'Purchases', 'icon': Icons.shopping_bag},
      {'title': 'Expenses', 'icon': Icons.money_off},
      {'title': 'Sales Report', 'icon': Icons.bar_chart},
      {'title': 'Stock Report', 'icon': Icons.inventory_2},
      {'title': 'Analytics', 'icon': Icons.analytics},
      {'title': 'Settings', 'icon': Icons.settings},
      {'title': 'Backup & Restore', 'icon': Icons.cloud_upload},
      {'title': 'Notifications', 'icon': Icons.notifications},
      {'title': 'User Management', 'icon': Icons.supervisor_account},
      {'title': 'Loyalty Program', 'icon': Icons.card_giftcard},
      {'title': 'Support', 'icon': Icons.headset_mic},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // یہ ضروری ہے gradient دکھانے کے لیے
        centerTitle: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const SizedBox(), // اگر back button نہیں چاہیے تو خالی رکھیں، ورنہ ہٹا دیں
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Get.to(() => NotificationScreen());
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            SalesAndTransactionsWidget(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              salesData: salesData,
            ),

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
              ],
            ),

            const SizedBox(height: 12),

            Obx(() {
              final favoriteActions = allQuickActions
                  .where((action) => favoritesController.favoriteActions
                      .contains(action['title']))
                  .toList();

              if (favoriteActions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 130),
                    child: Column(
                      children: const [
                        Text(
                          "No favorite actions yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                itemCount: favoriteActions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final action = favoriteActions[index];
                  return QuickActionCard(
                    title: action['title'] as String,
                    icon: action['icon'] as IconData,
                    color: const Color(0xFF253746),
                    cardSize: cardSize,
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
                        case 'Expenses':
                          Get.to(() => ExpensesScreen());
                          break;
                        case 'Notifications':
                          Get.to(() => NotificationScreen());
                          break;
                        case 'Suppliers':
                          Get.to(() => SuppliersScreen());
                          break;
                        case 'User Management':
                          Get.to(() => UserManagementScreen());
                          break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${action['title']} coming soon!"),
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