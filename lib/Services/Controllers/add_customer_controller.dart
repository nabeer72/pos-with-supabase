import 'package:flutter/material.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/customer_model.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';

enum CustomerType { regular, vip, wholesale }

class CustomerController extends GetxController {
  final customers = <CustomerModel>[].obs;
  final isLoading = true.obs;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    isLoading.value = true;
    final authController = Get.find<AuthController>();
    final list = await _dbHelper.getCustomers(adminId: authController.adminId);
    customers.assignAll(list);
    isLoading.value = false;
  }

  Future<void> addCustomer({
    required String name,
    required String address,
    required String cellNumber,
    required String email,
    required CustomerType type,
    required double discount,
  }) async {
    final authController = Get.find<AuthController>();
    final newCustomer = CustomerModel(
      name: name,
      address: address.isEmpty ? null : address,
      cellNumber: cellNumber.isEmpty ? null : cellNumber,
      email: email.isEmpty ? null : email,
      type: type,
      adminId: authController.adminId,
      discount: discount,
    );
    await _dbHelper.insertCustomer(newCustomer);
    await loadCustomers();
    
    // Trigger sync to Supabase
    SupabaseService().syncData();
  }

  Future<void> toggleCustomerStatus(int index) async {
    final customer = customers[index];
    final updatedCustomer = CustomerModel(
      id: customer.id,
      name: customer.name,
      address: customer.address,
      cellNumber: customer.cellNumber,
      email: customer.email,
      type: customer.type,
      isActive: !customer.isActive,
      supabaseId: customer.supabaseId,
      isSynced: false,
      adminId: customer.adminId,
      discount: customer.discount,
    );
    await _dbHelper.updateCustomer(updatedCustomer);
    await loadCustomers();
    
    // Trigger sync to Supabase
    SupabaseService().syncData();
  }
}