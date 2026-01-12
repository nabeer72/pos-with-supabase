import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/inventory_controller.dart';
import 'package:pos/Services/models/product_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InventoryController controller = Get.find<InventoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Obx(() {
        final favorites = controller.inventoryItems.where((p) => p.isFavorite).toList();
        
        if (favorites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No favorites yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final product = favorites[index];
            return _buildProductCard(context, product, controller);
          },
        );
      }),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, InventoryController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(product.color ?? 0xFFEEEEEE),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Icon(
                    product.icon,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                onPressed: () {
                  // Toggle favorite
                   // We need to update the product with specific fields changed
                   // Since product is immutable, we create a copy
                   // But Product model doesn't have copyWith yet? 
                   // Let's check or recreate.
                   final updated = Product(
                     id: product.id,
                     name: product.name,
                     price: product.price,
                     category: product.category,
                     icon: product.icon,
                     quantity: product.quantity,
                     barcode: product.barcode,
                     color: product.color,
                     supabaseId: product.supabaseId,
                     isSynced: product.isSynced,
                     isFavorite: !product.isFavorite, // Toggle
                   );
                   controller.updateProduct(updated);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
