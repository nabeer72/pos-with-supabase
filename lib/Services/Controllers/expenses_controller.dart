import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class ExpensesController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SupabaseService _supabase = SupabaseService();

  final RxList<Map<String, dynamic>> expenses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> expenseHeads = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  String? selectedHead; // used temporarily during dialog

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    await loadExpenseHeads();
    await loadExpenses();
    await _supabase.syncData();
    await loadExpenseHeads(); // refresh after sync
    isLoading.value = false;
  }

  Future<void> loadExpenseHeads() async {
    final auth = Get.find<AuthController>();
    final data = await _dbHelper.getExpenseHeads(adminId: auth.adminId);
    expenseHeads.assignAll(data);
  }

  Future<void> loadExpenses() async {
    final auth = Get.find<AuthController>();
    final data = await _dbHelper.getExpenses(adminId: auth.adminId);
    expenses.assignAll(data);
  }

  // ─── Expense Heads CRUD ────────────────────────────────────────

  Future<void> addExpenseHead(String name) async {
    if (name.trim().isEmpty) return;

    final auth = Get.find<AuthController>();
    isLoading.value = true;

    await _dbHelper.insertExpenseHead(name.trim(), adminId: auth.adminId);
    await _supabase.syncData();
    await loadExpenseHeads();

    isLoading.value = false;
  }

  Future<void> deleteExpenseHead(Map<String, dynamic> head) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;

    await _dbHelper.deleteExpenseHead(head['name'], adminId: auth.adminId);

    if (head['supabase_id'] != null) {
      await _supabase.deleteRow('expense_heads', head['supabase_id']);
    }

    await loadExpenseHeads();
    isLoading.value = false;
  }

  // ─── Expenses CRUD ─────────────────────────────────────────────

  Future<void> saveExpense({
    required String category,
    required double amount,
    Map<String, dynamic>? existing,
  }) async {
    final auth = Get.find<AuthController>();
    isLoading.value = true;

    final data = {
      'category': category,
      'amount': amount,
      'date': existing?['date'] ?? DateTime.now().toIso8601String(),
      'adminId': auth.adminId,
      'is_synced': 0,
    };

    if (existing != null) {
      await _dbHelper.updateExpense(existing['id'], data);
    } else {
      await _dbHelper.insertExpense(data);
    }

    await _supabase.syncData();
    await loadExpenses();

    isLoading.value = false;

    Get.snackbar(
      existing != null ? 'Success' : 'Success',
      existing != null ? 'Expense updated' : 'Expense added',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> deleteExpense(Map<String, dynamic> expense) async {
    isLoading.value = true;

    final supabaseId = expense['supabase_id'];

    await _dbHelper.deleteExpense(expense['id']);

    if (supabaseId != null) {
      await _supabase.deleteRow('expenses', supabaseId);
    }

    await loadExpenses();
    isLoading.value = false;

    Get.snackbar(
      'Success',
      'Expense deleted',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.deepOrangeAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }
}