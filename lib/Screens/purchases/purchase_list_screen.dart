
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Purchase Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadPurchaseOrders(),
          )
        ],
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
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', context),
                  _buildFilterChip('Draft', context),
                  _buildFilterChip('Ordered', context),
                  _buildFilterChip('Partial', context),
                  _buildFilterChip('Received', context),
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
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey[400]),
                       const SizedBox(height: 12),
                       Text(
                         'No Purchase Orders',
                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                       ),
                     ],
                   ),
                 );
              }
              return ListView.builder(
                itemCount: controller.purchaseOrders.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ]
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, BuildContext context) {
    // We might want to make this reactive to show selected state, 
    // but for now let's just style it nicely.
    // Ideally the controller should expose 'currentFilter'.
    // Assuming controller.currentFilter is not easily available without editing it, 
    // we'll keep the interaction simple.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => controller.loadPurchaseOrders(statusFilter: label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
          child: Text(
            label, 
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)
          ),
        ),
      ),
    );
  }

  Widget _buildPOCard(BuildContext context, PurchaseOrder po) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showActionSheet(context, po),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(239, 246, 255, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color.fromRGBO(59, 130, 246, 1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        po.supplierName ?? 'Unknown Supplier',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.numbers, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'PO #${po.id}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            po.orderDate.split('T').first, // Simple date format
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${po.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(po.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    switch (status) {
      case 'Received': 
        color = const Color(0xFF10B981); // Emerald 500
        bgColor = const Color(0xFFD1FAE5); // Emerald 100
        break;
      case 'Partial': 
        color = const Color(0xFFF59E0B); // Amber 500
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        break;
      case 'Draft': 
        color = const Color(0xFF64748B); // Slate 500
        bgColor = const Color(0xFFF1F5F9); // Slate 100
        break;
      case 'Ordered': 
        color = const Color(0xFF3B82F6); // Blue 500
        bgColor = const Color(0xFFDBEAFE); // Blue 100
        break;
      default: 
        color = Colors.black;
        bgColor = Colors.grey[200]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status, 
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)
      ),
    );
  }

  void _showActionSheet(BuildContext context, PurchaseOrder po) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Text('Actions for PO #${po.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ),
            if (po.status != 'Received' && po.status != 'Cancelled')
              ListTile(
                leading: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                   child: const Icon(Icons.inventory, color: Colors.green)
                ),
                title: const Text('Receive Goods', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                   Get.back();
                   Get.to(() => ReceivePurchaseScreen(poId: po.id!));
                },
              ),
            ListTile(
              leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                 child: const Icon(Icons.delete, color: Colors.red)
              ),
              title: const Text('Delete PO', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Get.back();
                controller.deletePO(po.id!);
              },
            ),
             ListTile(
              leading: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                 child: const Icon(Icons.close, color: Colors.black)
              ),
              title: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Get.back(),
            ),
          ],
        ),
      )
    );
  }
}
