
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/purchase_controller.dart';
import 'package:pos/Services/models/purchase_model.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/models/product_model.dart';

import 'package:pos/Services/currency_service.dart';

class CreatePurchaseScreen extends StatefulWidget {
  @override
  _CreatePurchaseScreenState createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final PurchaseController controller = Get.find<PurchaseController>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CurrencyService _currencyService = CurrencyService();
  
  List<Map<String, dynamic>> suppliers = [];
  int? selectedSupplierId;
  String? selectedSupplierName;
  String currencySymbol = '\$'; // Default
  
  final TextEditingController notesController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController chequeNumberController = TextEditingController();
  String selectedPaymentType = 'Cash';
  
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
    _currencyService.setCurrentAdminId(adminId!);
    final currency = await _currencyService.loadCurrency();
    
    final supps = await _dbHelper.getSuppliers(adminId: adminId);
    final prods = await _dbHelper.getProducts(adminId: adminId);
    
    setState(() {
      suppliers = supps;
      allProducts = prods;
      currencySymbol = currency.symbol;
    });
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        Product? selectedProduct;
        final qtyController = TextEditingController(text: '1');
        final costController = TextEditingController(text: '0.0');
        final sellPriceController = TextEditingController(text: '0.0');
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   DropdownButtonFormField<Product>(
                    isExpanded: true,
                    hint: const Text('Select Product'),
                    items: allProducts.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                       setDialogState(() {
                         selectedProduct = val;
                         costController.text = val?.purchasePrice?.toString() ?? '0.0';
                         sellPriceController.text = val?.price.toString() ?? '0.0';
                       });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (selectedProduct != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sale Price: $currencySymbol${selectedProduct!.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blueGrey)),
                        Text('Last Cost: $currencySymbol${selectedProduct!.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sellPriceController,
                    decoration: InputDecoration(labelText: 'Selling Price ($currencySymbol)', border: const OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: costController,
                    decoration: InputDecoration(labelText: 'Purchase Price ($currencySymbol)', border: const OutlineInputBorder()),
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
                          sellingPrice: double.tryParse(sellPriceController.text) ?? 0.0,
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
      Get.snackbar('Error', 'Please select a supplier', snackPosition: SnackPosition.TOP);
      return;
    }
    if (items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.TOP);
      return;
    }

    final newPO = PurchaseOrder(
      supplierId: selectedSupplierId,
      orderDate: dateController.text,
      status: 'Received', 
      totalAmount: grandTotal,
      notes: notesController.text,
      invoiceNumber: invoiceController.text,
      paymentType: selectedPaymentType,
      bankName: selectedPaymentType == 'Bank' ? bankNameController.text : null,
      chequeNumber: selectedPaymentType == 'Cheque' ? chequeNumberController.text : null,
      adminId: Get.find<AuthController>().adminId,
      items: items,
    );
    
    controller.createDirectPurchase(newPO);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Supplier
            DropdownButtonFormField<int>(
             
              value: selectedSupplierId,
              decoration: InputDecoration(
                labelText: 'Supplier', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50]
              ),
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
            const SizedBox(height: 16),
            // Date
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Purchase Date', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.grey[50]
              ),
              onTap: () async {
                 DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                 if (picked != null) {
                   dateController.text = picked.toString().split(' ')[0];
                 }
              },
              readOnly: true,
            ),
             const SizedBox(height: 16),
            // Notes
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50]
              ),
            ),
            const SizedBox(height: 16),
            // Invoice & Payment
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: invoiceController,
                    decoration: InputDecoration(
                      labelText: 'Invoice Number', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50]
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPaymentType,
                    decoration: InputDecoration(
                      labelText: 'Payment Type', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50]
                    ),
                    items: ['Cash', 'Bank', 'Cheque'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedPaymentType = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (selectedPaymentType == 'Bank') ...[
              const SizedBox(height: 16),
              TextField(
                controller: bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50]
                ),
              ),
            ],
            if (selectedPaymentType == 'Cheque') ...[
              const SizedBox(height: 16),
              TextField(
                controller: chequeNumberController,
                decoration: InputDecoration(
                  labelText: 'Cheque Number', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50]
                ),
              ),
            ],
            const SizedBox(height: 24),
            
            // Items Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                TextButton.icon(
                  onPressed: _addItem, 
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  label: const Text('Add Item', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                )
              ],
            ),
            const Divider(thickness: 1),
            
            // Items List
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text('No items added', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_,__) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final subtotal = item.quantity * item.unitCost;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${item.quantity} x $currencySymbol${item.unitCost.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$currencySymbol${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => items.removeAt(index)))
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
                   Text('$currencySymbol${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: () => _saveOrder('Received'),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    child: const Text('Save Purchase', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
