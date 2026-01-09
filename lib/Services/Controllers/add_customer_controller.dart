import 'package:flutter/material.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/customer_model.dart';

enum CustomerType { regular, vip, wholesale }

class CustomerController {
  List<CustomerModel> customers = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> loadCustomers() async {
    customers = await _dbHelper.getCustomers();
  }

  Future<void> addCustomer(
    BuildContext context,
    String name,
    String address,
    String cellNumber,
    String email,
    CustomerType type,
  ) async {
    final newCustomer = CustomerModel(
      name: name,
      address: address.isEmpty ? null : address,
      cellNumber: cellNumber.isEmpty ? null : cellNumber,
      email: email.isEmpty ? null : email,
      type: type,
    );
    await _dbHelper.insertCustomer(newCustomer);
    await loadCustomers();
  }

  void toggleCustomerStatus(int index) {
     // Optional: Implement toggle status in DB
  }
}