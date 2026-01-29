
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/purchase_controller.dart';
import 'package:pos/Services/models/purchase_model.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/widgets/custom_loader.dart';

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
    if (isLoading) return const Scaffold(body: Center(child: LoadingWidget()));
    if (po == null) return const Scaffold(body: Center(child: Text('Purchase Order not found')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Receive Purchase #${po!.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(239, 246, 255, 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(59, 130, 246, 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Color.fromRGBO(59, 130, 246, 1), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        po!.supplierName ?? 'Unknown Supplier',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(po!.orderDate.split('T').first, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(po!.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items to Receive', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                Text('${po!.items.length} items', style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: po!.items.length,
              itemBuilder: (context, index) {
                final item = po!.items[index];
                final remaining = item.quantity - item.receivedQuantity;
                final isFullyReceived = remaining <= 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isFullyReceived ? Colors.grey.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isFullyReceived ? Colors.grey.shade300 : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isFullyReceived ? Colors.green.shade50 : const Color.fromRGBO(239, 246, 255, 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFullyReceived ? Icons.check_circle : Icons.inventory_2,
                            color: isFullyReceived ? Colors.green : const Color.fromRGBO(59, 130, 246, 1),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Product #${item.productId}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isFullyReceived ? Colors.grey : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Ordered: ${item.quantity}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  const SizedBox(width: 12),
                                  Text('Received: ${item.receivedQuantity}', style: TextStyle(fontSize: 12, color: isFullyReceived ? Colors.green : const Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const Text('Receive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              TextField(
                                controller: receiveControllers[item.id!],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  filled: true,
                                  fillColor: isFullyReceived ? Colors.grey.shade100 : Colors.white,
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
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _confirmReceive,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color.fromARGB(255, 34, 197, 94)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Confirm Receipt & Update Inventory', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
