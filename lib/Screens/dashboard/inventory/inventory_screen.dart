import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Screens/dashboard/inventory/add_product_screen.dart';
import 'package:pos/widgets/action_card.dart';
import 'package:pos/widgets/custom_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/Services/Controllers/inventory_controller.dart';
import 'package:pos/widgets/custom_loader.dart';

class InventoryScreen extends StatelessWidget {
  InventoryScreen({super.key});

  final InventoryController controller = Get.put(InventoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: RefreshIndicator(
        onRefresh: () => controller.loadInventory(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.05,
                vertical: constraints.maxHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: constraints.maxHeight * 0.02),
                  _buildInventoryGrid(context, constraints.maxWidth),
                  SizedBox(height: constraints.maxHeight * 0.03),
                  _buildAddInventoryButton(context, constraints.maxWidth),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  _buildInventorySummary(context, constraints.maxWidth, constraints.maxHeight),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryGrid(BuildContext context, double screenWidth) {
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isTablet ? (isLandscape ? 6 : 4) : (isLandscape ? 5 : 3);
    final cardSize = screenWidth / crossAxisCount - 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.inventoryItems.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No items in inventory', style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: controller.inventoryItems.length,
            itemBuilder: (context, index) {
              final item = controller.inventoryItems[index];
              return QuickActionCard(
                title: item.name,
                price: item.price,
                icon: item.icon,
                color: item.color != null ? Color(item.color!) : const Color(0xFF253746),
                cardSize: cardSize,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${item.name}')),
                  );
                },
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildAddInventoryButton(BuildContext context, double screenWidth) {
    return CustomButton(
      text: 'Add to Inventory',
      onPressed: () => Get.to(() => const AddProductScreen()),
    );
  }

  Widget _buildInventorySummary(BuildContext context, double screenWidth, double screenHeight) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Summary',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.inventoryItems.isEmpty) {
                return const SizedBox(height: 50, child: Center(child: Text('Empty summary')));
              }
              return SizedBox(
                height: screenHeight * 0.3,
                child: ListView.builder(
                  itemCount: controller.inventoryItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.inventoryItems[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                          'Price: Rs. ${item.price.toStringAsFixed(2)}${item.barcode != null ? " | QR: ${item.barcode}" : ""}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(item.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: item.isFavorite ? Colors.red : Colors.grey),
                            onPressed: () {
                              final updated = Product(
                                id: item.id,
                                name: item.name,
                                barcode: item.barcode,
                                price: item.price,
                                category: item.category,
                                icon: item.icon,
                                quantity: item.quantity,
                                color: item.color,
                                supabaseId: item.supabaseId,
                                isSynced: item.isSynced,
                                isFavorite: !item.isFavorite,
                                purchasePrice: item.purchasePrice,
                              );
                              controller.updateProduct(updated);
                            },
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                            onPressed: () {
                              final updated = Product(
                                id: item.id,
                                name: item.name,
                                barcode: item.barcode,
                                price: item.price,
                                category: item.category,
                                icon: item.icon,
                                quantity: item.quantity + 1,
                                color: item.color,
                                purchasePrice: item.purchasePrice,
                              );
                              controller.updateProduct(updated);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}



