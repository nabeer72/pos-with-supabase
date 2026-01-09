import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/product_model.dart';

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
      final items = await _dbHelper.getProducts();
      inventoryItems.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    final cats = await _dbHelper.getCategories();
    categories.assignAll(cats);
  }

  Future<void> addProduct(Product product) async {
    await _dbHelper.insertProduct(product);
    await loadInventory();
  }

  Future<void> updateProduct(Product product) async {
    await _dbHelper.updateProduct(product);
    await loadInventory();
  }

  Future<void> deleteProduct(int id) async {
    await _dbHelper.deleteProduct(id);
    await loadInventory();
  }

  Future<void> addCategory(String name) async {
    await _dbHelper.insertCategory(name);
    await loadCategories();
  }
}
