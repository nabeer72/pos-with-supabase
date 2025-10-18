import 'package:flutter/material.dart';
import 'package:pos/widgets/notification_card.dart';
class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // Dummy expense data for POS
  List<Map<String, String>> expenses = [
    {
      'category': 'Utilities',
      'amount': '\$150.00',
      'date': 'Oct 15, 2025',
    },
    {
      'category': 'Supplies',
      'amount': '\$300.00',
      'date': 'Oct 12, 2025',
    },
    {
      'category': 'Maintenance',
      'amount': '\$75.50',
      'date': 'Oct 10, 2025',
    },
  ];

  // Function to show dialog for adding or editing an expense
  void _showExpenseDialog({Map<String, String>? expense, int? index}) {
    final categoryController = TextEditingController(text: expense?['category'] ?? '');
    final amountController = TextEditingController(text: expense?['amount']?.replaceAll('\$', '') ?? '');
    final isEdit = expense != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Expense' : 'Add Expense',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
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
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            TextField(
              controller: amountController,
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14),
            ),
          ],
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
            onPressed: () {
              if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text);
                if (amount != null) {
                  setState(() {
                    final newExpense = {
                      'category': categoryController.text,
                      'amount': '\$${amount.toStringAsFixed(2)}',
                      'date': isEdit ? expense['date']! : 'Oct 18, 2025',
                    };
                    if (isEdit) {
                      expenses[index!] = newExpense;
                    } else {
                      expenses.add(newExpense);
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'Expense updated' : 'Expense added'),
                      backgroundColor: Colors.deepOrangeAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              isEdit ? 'Update' : 'Add',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
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
            onPressed: () {
              setState(() {
                expenses.removeAt(index);
              });
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
        title: Text(
          'Expenses',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
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
                  subtitle: expense['amount']!,
                  trailingText: expense['date']!,
                  avatarIcon: Icons.account_balance_wallet,
                  onAvatarTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped: ${expense['category']}'),
                        backgroundColor: Colors.deepOrangeAccent,
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
        backgroundColor: Colors.deepOrangeAccent,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}