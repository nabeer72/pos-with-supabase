import 'package:flutter/material.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/customer_model.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';

enum CustomerType { regular, vip, wholesale }

class CustomerController {
  List<CustomerModel> customers = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> loadCustomers() async {
    final authController = Get.find<AuthController>();
    customers = await _dbHelper.getCustomers(adminId: authController.adminId);
  }

  Future<void> addCustomer(
    BuildContext context,
    String name,
    String address,
    String cellNumber,
    String email,
    CustomerType type,
    double discount,
  ) async {
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