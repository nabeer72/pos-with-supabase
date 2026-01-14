import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class InventoryController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  final inventoryItems = <Product>[].obs;
  final categories = <String>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInventory();
    loadCategories();
  }

  Future<void> loadInventory() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final items = await _dbHelper.getProducts(adminId: authController.adminId);
      inventoryItems.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    final authController = Get.find<AuthController>();
    final cats = await _dbHelper.getCategories(adminId: authController.adminId);
    categories.assignAll(cats);
  }

  Future<void> addProduct(Product product) async {
    final authController = Get.find<AuthController>();
    final productWithAdmin = Product(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      category: product.category,
      icon: product.icon,
      quantity: product.quantity,
      color: product.color,
      supabaseId: product.supabaseId,
      isSynced: product.isSynced,
      isFavorite: product.isFavorite,
      purchasePrice: product.purchasePrice,
      adminId: authController.adminId, // Assign current Admin ID
    );
    await _dbHelper.insertProduct(productWithAdmin);
    await loadInventory();
    SupabaseService().syncData(); // Trigger sync
  }

  Future<void> updateProduct(Product product) async {
    await _dbHelper.updateProduct(product);
    await loadInventory();
    SupabaseService().syncData(); // Trigger sync
  }

  Future<void> deleteProduct(int id) async {
    await _dbHelper.deleteProduct(id);
    await loadInventory();
    SupabaseService().syncData(); // Trigger sync
  }

  Future<void> addCategory(String name) async {
    final authController = Get.find<AuthController>();
    await _dbHelper.insertCategory(name, adminId: authController.adminId);
    await loadCategories();
    SupabaseService().syncData(); // Trigger sync
  }
}
