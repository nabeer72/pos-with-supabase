
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/purchase_controller.dart';
import 'package:pos/Services/models/purchase_model.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/models/product_model.dart';

class CreatePurchaseScreen extends StatefulWidget {
  @override
  _CreatePurchaseScreenState createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final PurchaseController controller = Get.find<PurchaseController>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Map<String, dynamic>> suppliers = [];
  int? selectedSupplierId;
  String? selectedSupplierName;
  
  final TextEditingController notesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  
  List<PurchaseItem> items = [];
  
  List<Product> allProducts = [];

  @override
  void initState() {
    super.initState();
    dateController.text = DateTime.now().toString().split(' ')[0];
    _loadData();
  }

  Future<void> _loadData() async {
    final adminId = Get.find<AuthController>().adminId;
    final supps = await _dbHelper.getSuppliers(adminId: adminId);
    final prods = await _dbHelper.getProducts(adminId: adminId);
    setState(() {
      suppliers = supps;
      allProducts = prods;
    });
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        Product? selectedProduct;
        final qtyController = TextEditingController(text: '1');
        final costController = TextEditingController(text: '0.0');
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Product>(
                    hint: const Text('Select Product'),
                    items: allProducts.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (val) {
                       setDialogState(() {
                         selectedProduct = val;
                         // Default cost to current purchase price
                         costController.text = val?.purchasePrice?.toString() ?? '0.0';
                       });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: costController,
                    decoration: const InputDecoration(labelText: 'Unit Cost'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProduct != null) {
                      setState(() {
                        items.add(PurchaseItem(
                          productId: selectedProduct!.id!,
                          productName: selectedProduct!.name,
                          quantity: int.tryParse(qtyController.text) ?? 1,
                          unitCost: double.tryParse(costController.text) ?? 0.0,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                )
              ],
            );
          }
        );
      }
    );
  }

  double get grandTotal {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitCost));
  }

  void _saveOrder(String status) {
    if (selectedSupplierId == null) {
      Get.snackbar('Error', 'Please select a supplier');
      return;
    }
    if (items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item');
      return;
    }

    final newPO = PurchaseOrder(
      supplierId: selectedSupplierId,
      orderDate: dateController.text,
      status: status,
      totalAmount: grandTotal,
      notes: notesController.text,
      adminId: Get.find<AuthController>().adminId,
      items: items,
    );
    
    controller.createPurchaseOrder(newPO);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Order'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Supplier
            DropdownButtonFormField<int>(
              value: selectedSupplierId,
              decoration: const InputDecoration(labelText: 'Supplier', border: OutlineInputBorder()),
              items: suppliers.map((s) => DropdownMenuItem<int>(
                value: s['id'], 
                child: Text(s['name']),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSupplierId = val;
                  selectedSupplierName = suppliers.firstWhere((s) => s['id'] == val)['name'];
                });
              },
            ),
            const SizedBox(height: 12),
            // Date
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Order Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              onTap: () async {
                 DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                 if (picked != null) {
                   dateController.text = picked.toString().split(' ')[0];
                 }
              },
              readOnly: true,
            ),
             const SizedBox(height: 12),
            // Notes
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            // Items Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.blueGrey), onPressed: _addItem)
              ],
            ),
            const Divider(),
            
            // Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_,__) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                final subtotal = item.quantity * item.unitCost;
                return ListTile(
                  title: Text(item.productName ?? 'Product #${item.productId}'),
                  subtitle: Text('${item.quantity} x \$${item.unitCost.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => items.removeAt(index)))
                    ],
                  ),
                );
              },
            ),
            
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   Text('\$${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _saveOrder('Draft'), child: const Text('Save as Draft'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: () => _saveOrder('Ordered'), 
                  child: const Text('Place Order', style: TextStyle(color: Colors.white))
                )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
