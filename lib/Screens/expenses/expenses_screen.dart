import 'package:flutter/material.dart';
import 'package:pos/widgets/expense_card.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:pos/widgets/currency_text.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/supabase_service.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> expenseHeads = [];
  String? selectedHead;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadExpenseHeads();
    await _loadExpenses();
    await SupabaseService().syncData();
    await _loadExpenseHeads();
    setState(() => _isLoading = false);
  }

  Future<void> _loadExpenseHeads() async {
    final authController = Get.find<AuthController>();
    final data = await _dbHelper.getExpenseHeads(adminId: authController.adminId);
    setState(() {
      expenseHeads = data;
    });
  }

  Future<void> _loadExpenses() async {
    final authController = Get.find<AuthController>();
    final data = await _dbHelper.getExpenses(adminId: authController.adminId);
    setState(() {
      expenses = data;
    });
  }

  Future<void> _showManageHeadsDialog() async {
    final headController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Manage Expense Heads'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: headController,
                decoration: const InputDecoration(hintText: 'New Head Name (e.g., Rent)'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: expenseHeads.isEmpty
                    ? const Center(child: Text('No heads added yet'))
                    : ListView.builder(
                        itemCount: expenseHeads.length,
                        itemBuilder: (context, index) {
                          final head = expenseHeads[index];
                          return ListTile(
                            title: Text(head['name']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                final authController = Get.find<AuthController>();
                                // Delete locally
                                await _dbHelper.deleteExpenseHead(head['name'], adminId: authController.adminId);
                                
                                // Delete remotely
                                if (head['supabase_id'] != null) {
                                  await SupabaseService().deleteRow('expense_heads', head['supabase_id']);
                                }

                                await _loadExpenseHeads();
                                setDialogState(() {});
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
            ElevatedButton(
              onPressed: () async {
                final name = headController.text.trim();
                if (name.isNotEmpty) {
                  final authController = Get.find<AuthController>();
                  
                  // Show loader, close dialog first or handle state?
                  // User wants loader shown on screen. 
                  Navigator.pop(context); 
                  setState(() => _isLoading = true);
                  
                  await _dbHelper.insertExpenseHead(name, adminId: authController.adminId);
                  headController.clear();
                  await SupabaseService().syncData();
                  await _loadExpenseHeads();
                  
                  setState(() => _isLoading = false);
                  // Re-open dialog? logic implies we are managing heads. 
                  // Usually we'd keep dialog open. But if we show loader in body, we need to see body.
                  // Or we can show loader IN dialog.
                  // User said "loader in expenses screen". 
                  // Let's assume body loader.
                  _showManageHeadsDialog(); // Re-open to continue managing
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show dialog for adding or editing an expense
  void _showExpenseDialog({Map<String, dynamic>? expense, int? index}) {
  selectedHead = expense?['category']; // Keeping 'category' in DB but mapping to Head name in UI
  final amountController = TextEditingController(text: expense?['amount']?.toString() ?? '');
  final isEdit = expense != null;

  showDialog(
    context: context,
    barrierDismissible: true, // Tap outside to close
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [ // ...
            Text(
              isEdit ? 'Edit Expense' : 'Add Expense',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedHead,
                    dropdownColor: Colors.white,
                    items: expenseHeads.map((head) => DropdownMenuItem(
                      value: head['name'] as String,
                      child: Text(head['name'], style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedHead = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Select Head',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                  onPressed: () async {
                    await _showManageHeadsDialog();
                    // After returning, refresh heads in this dialog
                    await _loadExpenseHeads();
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Amount (e.g., 150.00)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () async {
              final head = selectedHead;
              final amountText = amountController.text.trim();
  
              if (head == null || amountText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
  
              final amount = double.tryParse(amountText);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
  
              Navigator.pop(context); // Close dialog first to show loader on screen
              setState(() => _isLoading = true);
              
              final authController = Get.find<AuthController>();
              final newExpense = {
                'category': head, // Save Head name as category for now to maintain consistency
                'amount': amount,
                'date': isEdit ? expense['date']! : DateTime.now().toIso8601String(),
                'adminId': authController.adminId,
                'is_synced': 0, // Mark for sync
              };
  
              if (isEdit) {
                await _dbHelper.updateExpense(expense['id'], newExpense);
              } else {
                await _dbHelper.insertExpense(newExpense);
              }
              
              // Trigger background sync
              await SupabaseService().syncData();
              
              await _loadExpenses();
              
              setState(() => _isLoading = false);
  
              Get.snackbar(
                isEdit ? 'Success' : 'Success',
                isEdit ? 'Expense updated' : 'Expense added',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(30, 58, 138, 1),
                    Color.fromRGBO(59, 130, 246, 1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 40),
                child: Text(
                  isEdit ? 'Update' : 'Add',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
  );
}

  // Function to delete an expense
  void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Expense',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to delete ${expenses[index]['category']} expense?',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final expense = expenses[index];
              final supabaseId = expense['supabase_id'];
              
              // 1. Delete Locally
              await _dbHelper.deleteExpense(expense['id']);
              
              // 2. Delete Remotely if it exists in Supabase
              if (supabaseId != null) {
                await SupabaseService().deleteRow('expenses', supabaseId);
              }
              
              await _loadExpenses();
              setState(() => _isLoading = false);
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Expenses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
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
      body: _isLoading 
          ? const Center(child: LoadingWidget()) 
          : expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 50, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'No Expenses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return ExpenseCard(
                  category: expense['category']!,
                  amount: (expense['amount'] as num).toDouble(),
                  date: expense['date']!,
                  onEdit: () => _showExpenseDialog(expense: expense, index: index),
                  onDelete: () => _deleteExpense(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpenseDialog,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(30, 58, 138, 1),
                Color.fromRGBO(59, 130, 246, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}