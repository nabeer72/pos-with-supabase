import 'package:flutter/material.dart';
import 'package:pos/widgets/notification_card.dart';
import 'package:pos/widgets/currency_text.dart';
import 'package:pos/Services/database_helper.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await _dbHelper.getExpenses();
    setState(() {
      // Map back to String for UI if needed, or update UI to handle dynamic
      expenses = data;
    });
  }

  // Function to show dialog for adding or editing an expense
void _showExpenseDialog({Map<String, dynamic>? expense, int? index}) {
  final categoryController = TextEditingController(text: expense?['category'] ?? '');
  final amountController = TextEditingController(text: expense?['amount']?.toString().replaceAll('Rs.', '').trim() ?? '');
  final isEdit = expense != null;

  showDialog(
    context: context,
    barrierDismissible: true, // Tap outside to close
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEdit ? 'Edit Expense' : 'Add Expense',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          // Close icon added here
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
          TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: 'Category (e.g., Utilities)',
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
        // Only the gradient Add/Update button (no Cancel button)
        ElevatedButton(
            onPressed: () async {
            final category = categoryController.text.trim();
            final amountText = amountController.text.trim();

            if (category.isEmpty || amountText.isEmpty) {
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

            final newExpense = {
              'category': category,
              'amount': amount,
              'date': isEdit ? expense['date']! : DateTime.now().toIso8601String(),
            };

            if (isEdit) {
              await _dbHelper.updateExpense(int.parse(expense['id']!), newExpense);
            } else {
              await _dbHelper.insertExpense(newExpense);
            }
            await _loadExpenses();

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEdit ? 'Expense updated' : 'Expense added'),
                backgroundColor: Colors.deepOrangeAccent,
                duration: const Duration(seconds: 2),
              ),
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
  );
}

  // Function to delete an expense
  void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
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
              await _dbHelper.deleteExpense(expenses[index]['id']);
              await _loadExpenses();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Expense deleted'),
                  backgroundColor: Colors.deepOrangeAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
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
      body: expenses.isEmpty
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
                return CustomCardWidget(
                  title: expense['category']!,
                  subtitleWidget: CurrencyText(
                    price: (expense['amount'] as num).toDouble(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  trailingText: expense['date']!,
                  avatarIcon: Icons.account_balance_wallet,
                  onAvatarTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped: ${expense['category']}'),
                        backgroundColor: const Color.fromARGB(255, 75, 91, 234),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onCardTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: ${expense['category']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
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