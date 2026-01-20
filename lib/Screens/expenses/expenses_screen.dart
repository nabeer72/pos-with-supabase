import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/widgets/expense_card.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:pos/Services/Controllers/expenses_controller.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ExpensesController()); // Put to ensure initialization

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Expenses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(
        () => ctrl.isLoading.value
            ? const Center(child: LoadingWidget())
            : ctrl.expenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: ctrl.expenses.length,
                    itemBuilder: (context, index) {
                      final exp = ctrl.expenses[index];
                      return ExpenseCard(
                        category: exp['category']!,
                        amount: (exp['amount'] as num).toDouble(),
                        date: exp['date']!,
                        onEdit: () => _showExpenseDialog(context, ctrl, expense: exp),
                        onDelete: () => _confirmDelete(context, ctrl, exp),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseDialog(context, ctrl),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No Expenses',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showExpenseDialog(
    BuildContext context,
    ExpensesController ctrl, {
    Map<String, dynamic>? expense,
  }) {
    final isEdit = expense != null;
    final amountCtrl = TextEditingController(text: expense?['amount']?.toString() ?? '');
    String? selectedHead = expense?['category'] as String?;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
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
                        items: ctrl.expenseHeads
                            .map((h) => DropdownMenuItem(
                                  value: h['name'] as String,
                                  child: Text(h['name'], style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedHead = val),
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
                        await _showManageHeadsDialog(context, ctrl);
                        await ctrl.loadExpenseHeads();
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
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
                  final amountText = amountCtrl.text.trim();

                  if (head == null || amountText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }

                  final amount = double.tryParse(amountText);
                  if (amount == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  await ctrl.saveExpense(
                    category: head,
                    amount: amount,
                    existing: expense,
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
                      colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        },
      ),
    );
  }

  Future<void> _showManageHeadsDialog(BuildContext context, ExpensesController ctrl) async {
    final headController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                  child: ctrl.expenseHeads.isEmpty
                      ? const Center(child: Text('No heads added yet'))
                      : ListView.builder(
                          itemCount: ctrl.expenseHeads.length,
                          itemBuilder: (context, index) {
                            final head = ctrl.expenseHeads[index];
                            return ListTile(
                              title: Text(head['name']),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  await ctrl.deleteExpenseHead(head);
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
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = headController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(context);
                    await ctrl.addExpenseHead(name);
                    // Allow continuing to manage heads
                    _showManageHeadsDialog(context, ctrl);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpensesController ctrl, Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: const Text('Delete Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        content: Text(
          'Are you sure you want to delete ${expense['category']} expense?',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ctrl.deleteExpense(expense);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}