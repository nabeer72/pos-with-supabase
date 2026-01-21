
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/supplier_model.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/supabase_service.dart';

class SupplierController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthController _authController = Get.find<AuthController>();
  final SupabaseService _supabaseService = SupabaseService();

  var suppliers = <Supplier>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    isLoading.value = true;
    try {
      final adminId = _authController.adminId;
      final data = await _dbHelper.getSuppliers(adminId: adminId);
      suppliers.value = data.map((e) => Supplier.fromMap(e)).toList();
    } catch (e) {
      print('Error loading suppliers: $e');
      Get.snackbar('Error', 'Failed to load suppliers');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSupplier(String name, String contact) async {
    isLoading.value = true;
    try {
      final newSupplier = Supplier(
        name: name,
        contact: contact,
        lastOrder: DateTime.now().toIso8601String(), // Initially creation date
        adminId: _authController.adminId,
        isSynced: 0
      );
      
      final id = await _dbHelper.insertSupplier(newSupplier.toMap());
      // Ideally update model with ID
      loadSuppliers();
      Get.back(); // Close dialog
      Get.snackbar('Success', 'Supplier added');
      
      // Trigger sync
      _supabaseService.pushUnsyncedData();
    } catch (e) {
      print('Error adding supplier: $e');
      Get.snackbar('Error', 'Failed to add supplier');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    isLoading.value = true;
    try {
       supplier.isSynced = 0; // Mark for sync
       await _dbHelper.updateSupplier(supplier.id!, supplier.toMap());
       loadSuppliers();
       Get.back();
       Get.snackbar('Success', 'Supplier updated');
       
       _supabaseService.pushUnsyncedData();
    } catch (e) {
      print('Error updating supplier: $e');
      Get.snackbar('Error', 'Failed to update supplier');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _dbHelper.deleteSupplier(id);
      loadSuppliers();
      Get.snackbar('Success', 'Supplier deleted');
    } catch (e) {
      print('Error deleting supplier: $e');
      Get.snackbar('Error', 'Failed to delete supplier');
    }
  }
}
