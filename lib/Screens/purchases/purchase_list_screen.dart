
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/purchase_controller.dart';
import 'package:pos/Services/models/purchase_model.dart';
import 'package:pos/Screens/purchases/create_purchase_screen.dart';
import 'package:pos/Screens/purchases/receive_purchase_screen.dart';
import 'package:intl/intl.dart';

class PurchaseListScreen extends StatelessWidget {
  final PurchaseController controller = Get.put(PurchaseController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadPurchaseOrders(),
          )
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Draft'),
                  _buildFilterChip('Ordered'),
                  _buildFilterChip('Partial'),
                  _buildFilterChip('Received'),
                ],
              ),
            ),
          ),
          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.purchaseOrders.isEmpty) {
                 return const Center(child: Text('No Purchase Orders found.'));
              }
              return ListView.builder(
                itemCount: controller.purchaseOrders.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final po = controller.purchaseOrders[index];
                  return _buildPOCard(context, po);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => CreatePurchaseScreen()),
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label),
        onPressed: () => controller.loadPurchaseOrders(statusFilter: label),
      ),
    );
  }

  Widget _buildPOCard(BuildContext context, PurchaseOrder po) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('${po.supplierName ?? 'Unknown Supplier'} (ID: ${po.id})', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${po.orderDate}'),
            Text('Amount: \$${po.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusBadge(po.status),
          ],
        ),
        onTap: () {
          _showActionSheet(context, po);
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Received': color = Colors.green; break;
      case 'Partial': color = Colors.orange; break;
      case 'Draft': color = Colors.grey; break;
      case 'Ordered': color = Colors.blue; break;
      default: color = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showActionSheet(BuildContext context, PurchaseOrder po) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            if (po.status != 'Received' && po.status != 'Cancelled')
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Receive Goods'),
                onTap: () {
                   Get.back();
                   Get.to(() => ReceivePurchaseScreen(poId: po.id!));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete PO', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                controller.deletePO(po.id!);
              },
            ),
             ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      )
    );
  }
}
