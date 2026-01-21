
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/supplier_controller.dart';
import 'package:pos/Services/models/supplier_model.dart';
import 'package:intl/intl.dart';

class SuppliersScreen extends StatelessWidget {
  final SupplierController controller = Get.put(SupplierController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.loadSuppliers(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.suppliers.isEmpty) {
          return const Center(child: Text('No Suppliers found.'));
        }
        return ListView.separated(
          itemCount: controller.suppliers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final supplier = controller.suppliers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.withOpacity(0.1),
                child: Text(supplier.name[0].toUpperCase(), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ),
              title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(supplier.contact),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                onPressed: () => _showSupplierDialog(context, supplier: supplier),
              ),
              onLongPress: () => _confirmDelete(context, supplier),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(context),
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showSupplierDialog(BuildContext context, {Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactController = TextEditingController(text: supplier?.contact ?? '');
    final isEdit = supplier != null;

    Get.dialog(
      AlertDialog(
        title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Store/Supplier Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact Info', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                if (isEdit) {
                  supplier.name = nameController.text;
                  supplier.contact = contactController.text;
                  controller.updateSupplier(supplier);
                } else {
                  controller.addSupplier(nameController.text, contactController.text);
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _confirmDelete(BuildContext context, Supplier supplier) {
    Get.defaultDialog(
      title: 'Delete Supplier',
      middleText: 'Are you sure you want to delete ${supplier.name}?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.deleteSupplier(supplier.id!);
      }
    );
  }
}