
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/supplier_controller.dart';
import 'package:pos/Services/models/supplier_model.dart';
import 'package:pos/widgets/custom_loader.dart';
import 'package:intl/intl.dart';

class SuppliersScreen extends StatelessWidget {
  final SupplierController controller = Get.put(SupplierController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Match background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Suppliers',
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }
        if (controller.suppliers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No Suppliers Found',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: controller.suppliers.length,
          itemBuilder: (context, index) {
            final supplier = controller.suppliers[index];
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(239, 246, 255, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color.fromRGBO(59, 130, 246, 1),
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                supplier.contact,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showSupplierDialog(context, supplier: supplier),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.edit_outlined, size: 20, color: Colors.blue[600]),
                          ),
                        ),
                        InkWell(
                          onTap: () => _confirmDelete(context, supplier),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red[400]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(context),
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

  void _showSupplierDialog(BuildContext context, {Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactController = TextEditingController(text: supplier?.contact ?? '');
    final isEdit = supplier != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Store/Supplier Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50]
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contactController,
              decoration: InputDecoration(
                labelText: 'Contact Info',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50]
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), 
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                 Get.back(); // Close dialog first
                if (isEdit) {
                  supplier.name = nameController.text;
                  supplier.contact = contactController.text;
                  controller.updateSupplier(supplier);
                } else {
                  controller.addSupplier(nameController.text, contactController.text);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color.fromRGBO(30, 58, 138, 1), Color.fromRGBO(59, 130, 246, 1)],
                )
              ),
              child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          )
        ],
      )
    );
  }

  void _confirmDelete(BuildContext context, Supplier supplier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              controller.deleteSupplier(supplier.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }
}