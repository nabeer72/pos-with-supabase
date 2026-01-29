import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';
import 'dart:convert';

class UserController extends GetxController {
  final _dbHelper = DatabaseHelper();
  var users = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      final adminId = Get.find<AuthController>().adminId;
      final data = await _dbHelper.getUsers(adminId: adminId);
      users.assignAll(data);
    } catch (e) {
      print('Error loading users: $e');
      Get.snackbar('Error', 'Failed to load users', 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      // Basic validation
      if (userData['name'].isEmpty || userData['email'].isEmpty) {
        Get.snackbar('Error', 'Name and Email are required',
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      userData['is_synced'] = 0;
      userData['adminId'] = Get.find<AuthController>().adminId;
      userData['lastActive'] = DateTime.now().toString();

      await _dbHelper.insertUser(userData);
      
      // Trigger sync
      try {
        await SupabaseService().pushUnsyncedData();
      } catch (e) {
        print("Sync error: $e");
      }

      await loadUsers();
      Get.back(); // Close dialog
      Get.snackbar('Success', 'User added successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add user: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      if (userData['name'].isEmpty || userData['email'].isEmpty) {
        Get.snackbar('Error', 'Name and Email are required',
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      userData['is_synced'] = 0;
      userData['lastActive'] = DateTime.now().toString(); // Update last active? Maybe not necessary for edit.

      await _dbHelper.updateUser(id, userData);
      
      // Trigger sync
      try {
        await SupabaseService().pushUnsyncedData();
      } catch (e) {
        print("Sync error: $e");
      }

      await loadUsers();
      Get.back(); // Close dialog
      Get.snackbar('Success', 'User updated successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteUser(int id, String? supabaseId) async {
    try {
      if (supabaseId != null) {
        try {
           await SupabaseService().deleteRow('users', supabaseId);
        } catch(e) {
          print("Remote delete failed: $e");
        }
      }

      await _dbHelper.deleteUser(id);
      await loadUsers();
      // Get.back(); // Dialog closed by caller usually?
      Get.snackbar('Success', 'User deleted successfully',
      
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete user: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
