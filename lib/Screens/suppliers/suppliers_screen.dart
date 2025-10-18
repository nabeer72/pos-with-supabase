import 'package:flutter/material.dart';
import 'package:pos/widgets/notification_card.dart';
class SuppliersScreen extends StatefulWidget {
  @override
  _SuppliersScreenState createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  // Dummy supplier data for POS
  List<Map<String, String>> suppliers = [
    {
      'name': 'Bean & Brew',
      'contact': 'contact@beanbrew.com',
      'lastOrder': 'Oct 15, 2025',
    },
    {
      'name': 'Fresh Foods',
      'contact': '+1-555-123-4567',
      'lastOrder': 'Oct 10, 2025',
    },
    {
      'name': 'Sweet Supplies',
      'contact': 'sweetsupply@gmail.com',
      'lastOrder': 'Oct 8, 2025',
    },
  ];

  // Function to show dialog for adding or editing a supplier
  void _showSupplierDialog({Map<String, String>? supplier, int? index}) {
    final nameController = TextEditingController(text: supplier?['name'] ?? '');
    final contactController = TextEditingController(text: supplier?['contact'] ?? '');
    final isEdit = supplier != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          isEdit ? 'Edit Supplier' : 'Add Supplier',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Supplier Name',
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
              controller: contactController,
              decoration: InputDecoration(
                hintText: 'Contact Info',
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
              if (nameController.text.isNotEmpty && contactController.text.isNotEmpty) {
                setState(() {
                  final newSupplier = {
                    'name': nameController.text,
                    'contact': contactController.text,
                    'lastOrder': isEdit ? supplier['lastOrder']! : 'Oct 18, 2025',
                  };
                  if (isEdit) {
                    suppliers[index!] = newSupplier;
                  } else {
                    suppliers.add(newSupplier);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Supplier updated' : 'Supplier added'),
                    backgroundColor: Colors.deepOrangeAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
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

  // Function to delete a supplier
  void _deleteSupplier(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          'Delete Supplier',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to delete ${suppliers[index]['name']}?',
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
                suppliers.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Supplier deleted'),
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
          'Suppliers',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
      ),
      body: suppliers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 50, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'No Suppliers',
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
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];
                return CustomCardWidget(
                  title: supplier['name']!,
                  subtitle: supplier['contact']!,
                  trailingText: supplier['lastOrder']!,
                  avatarIcon: Icons.business,
                  onAvatarTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tapped: ${supplier['name']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onCardTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected: ${supplier['name']}'),
                        backgroundColor: Colors.deepOrangeAccent,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onEdit: () => _showSupplierDialog(supplier: supplier, index: index),
                  onDelete: () => _deleteSupplier(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSupplierDialog,
        backgroundColor: Colors.deepOrangeAccent,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}