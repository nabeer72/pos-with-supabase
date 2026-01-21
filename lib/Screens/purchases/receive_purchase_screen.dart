
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/purchase_controller.dart';
import 'package:pos/Services/models/purchase_model.dart';
import 'package:pos/Services/models/product_model.dart';

class ReceivePurchaseScreen extends StatefulWidget {
  final int poId;
  const ReceivePurchaseScreen({required this.poId});

  @override
  _ReceivePurchaseScreenState createState() => _ReceivePurchaseScreenState();
}

class _ReceivePurchaseScreenState extends State<ReceivePurchaseScreen> {
  final PurchaseController controller = Get.find<PurchaseController>();
  PurchaseOrder? po;
  Map<int, TextEditingController> receiveControllers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPO();
  }

  Future<void> _loadPO() async {
    final details = await controller.getPurchaseOrderDetails(widget.poId);
    setState(() {
      po = details;
      isLoading = false;
      if (po != null) {
        for (var item in po!.items) {
           // Default to remaining quantity
           int remaining = item.quantity - item.receivedQuantity;
           receiveControllers[item.id!] = TextEditingController(text: remaining > 0 ? remaining.toString() : '0');
        }
      }
    });
  }

  void _confirmReceive() {
    if (po == null) return;
    
    List<PurchaseItem> itemsToReceive = [];
    
    for (var item in po!.items) {
       int qtyToReceive = int.tryParse(receiveControllers[item.id!]?.text ?? '0') ?? 0;
       if (qtyToReceive > 0) {
         // Create a copy or modify item to pass to controller
         // We use the 'receivedQuantity' field in the model to transport the "quantity being received NOW"
         // The controller understands this convention for the argument `receivedItems`
         var itemUpdate = PurchaseItem(
            id: item.id,
            purchaseId: item.purchaseId,
            productId: item.productId,
            quantity: item.quantity,
            receivedQuantity: qtyToReceive, // DELTA
            unitCost: item.unitCost
         );
         itemsToReceive.add(itemUpdate);
       }
    }

    if (itemsToReceive.isEmpty) {
      Get.snackbar('Info', 'No items to receive');
      return;
    }

    controller.receiveItems(po!.id!, itemsToReceive);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (po == null) return const Scaffold(body: Center(child: Text('Purchase Order not found')));

    return Scaffold(
      appBar: AppBar(
        title: Text('Receive PO #${po!.id}'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supplier: ${po!.supplierName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Date: ${po!.orderDate}'),
                Row(
                  children: [
                    const Text('Status: '),
                    Text(po!.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: po!.items.length,
              itemBuilder: (context, index) {
                final item = po!.items[index];
                final remaining = item.quantity - item.receivedQuantity;
                final isFullyReceived = remaining <= 0;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: isFullyReceived ? Colors.grey.shade100 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Ordered: ${item.quantity}'),
                              Text('Recv Before: ${item.receivedQuantity}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const Text('Receive Now'),
                              TextField(
                                controller: receiveControllers[item.id!],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                ),
                                enabled: !isFullyReceived,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _confirmReceive,
                child: const Text('Confirm Receipt & Update Inventory', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
