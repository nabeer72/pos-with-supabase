
import 'package:get/get.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:pos/Services/models/purchase_model.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:sqflite/sqflite.dart';

import 'package:pos/Services/supabase_service.dart';

class PurchaseController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthController _authController = Get.find<AuthController>();
  final SupabaseService _supabaseService = SupabaseService();

  var purchaseOrders = <PurchaseOrder>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPurchaseOrders();
  }

  Future<void> loadPurchaseOrders({String? statusFilter}) async {
    isLoading.value = true;
    try {
      final db = await _dbHelper.database;
      final adminId = _authController.adminId;
      
      String query = 'SELECT po.*, s.name as supplierName FROM purchase_orders po LEFT JOIN suppliers s ON po.supplierId = s.id';
      List<String> whereArgs = [];
      List<dynamic> args = [];

      if (adminId != null && adminId != '1') {
        whereArgs.add('po.adminId = ?');
        args.add(adminId);
      }
      
      if (statusFilter != null && statusFilter != 'All') {
        whereArgs.add('po.status = ?');
        args.add(statusFilter);
      }

      if (whereArgs.isNotEmpty) {
        query += ' WHERE ${whereArgs.join(' AND ')}';
      }
      
      query += ' ORDER BY po.orderDate DESC';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
      
      purchaseOrders.value = maps.map((map) => PurchaseOrder.fromMap(map, supplierName: map['supplierName'])).toList();
    } catch (e) {
      print('Error loading POs: $e');
      Get.snackbar('Error', 'Failed to load purchase orders');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createPurchaseOrder(PurchaseOrder po) async {
    isLoading.value = true;
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        // Insert PO
        int poId = await txn.insert('purchase_orders', po.toMap());
        po.id = poId;

        // Insert Items
        for (var item in po.items) {
          item.purchaseId = poId;
          item.adminId = po.adminId;
          await txn.insert('purchase_items', item.toMap());
        }
      });
      await loadPurchaseOrders();
      Get.back(); // Close form
      Get.snackbar('Success', 'Purchase Order created successfully');
      
      _supabaseService.pushUnsyncedData();
    } catch (e) {
      print('Error creating PO: $e');
      Get.snackbar('Error', 'Failed to create purchase order');
    } finally {
      isLoading.value = false;
    }
  }

  Future<PurchaseOrder?> getPurchaseOrderDetails(int id) async {
    final db = await _dbHelper.database;
    try {
      // Get PO
      final List<Map<String, dynamic>> poMaps = await db.rawQuery(
        'SELECT po.*, s.name as supplierName FROM purchase_orders po LEFT JOIN suppliers s ON po.supplierId = s.id WHERE po.id = ?', 
        [id]
      );
      
      if (poMaps.isEmpty) return null;

      // Get Items
      final List<Map<String, dynamic>> itemMaps = await db.rawQuery(
        'SELECT pi.*, p.name as productName FROM purchase_items pi LEFT JOIN products p ON pi.productId = p.id WHERE pi.purchaseId = ?',
        [id]
      );

      List<PurchaseItem> items = itemMaps.map((m) => PurchaseItem.fromMap(m, productName: m['productName'])).toList();
      
      return PurchaseOrder.fromMap(poMaps.first, items: items, supplierName: poMaps.first['supplierName']);
    } catch (e) {
      print('Error getting PO details: $e');
      return null;
    }
  }

  Future<void> receiveItems(int poId, List<PurchaseItem> receivedItems) async {
    // receivedItems contains items with UPDATED receivedQuantity (delta or total?)
    // Strategy: We pass the LIST of items that are being received in this session (delta).
    // Or we pass the state of the form. Let's assume we pass the User's input for "Buying Now" or "Receiving Now".
    
    // Easier approach: Pass the items with the QUANTITY BEING RECEIVED NOW.
    isLoading.value = true;
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        bool allFullyReceived = true;
        
        for (var receivedItem in receivedItems) {
           if (receivedItem.receivedQuantity > 0) { // Quantity being received NOW
             // 1. Fetch current item state to get total received so far
             final List<Map<String, dynamic>> currentItem = await txn.query('purchase_items', where: 'id = ?', whereArgs: [receivedItem.id]);
             if (currentItem.isEmpty) continue;
             
             int oldReceivedTotal = currentItem.first['receivedQuantity'] as int;
             int orderedQty = currentItem.first['quantity'] as int;
             int newReceivedTotal = oldReceivedTotal + receivedItem.receivedQuantity; // Add delta
             
             // Update Purchase Item
             await txn.update(
               'purchase_items', 
               {
                 'receivedQuantity': newReceivedTotal,
                 'is_synced': 0
               },
               where: 'id = ?',
               whereArgs: [receivedItem.id]
             );

             // 2. Update Inventory & Cost
             final productId = currentItem.first['productId'] as int;
             final unitCost = currentItem.first['unitCost'] as double;
             
             // Get Product
             final List<Map<String, dynamic>> productMap = await txn.query('products', where: 'id = ?', whereArgs: [productId]);
             if (productMap.isNotEmpty) {
               Product product = Product.fromMap(productMap.first);
               
               // Weighted Average Cost Calculation
               double oldTotalValue = product.quantity * product.purchasePrice; // Assuming purchasePrice is current Avg Cost
               double incomingValue = receivedItem.receivedQuantity * unitCost;
               int newTotalQty = product.quantity + receivedItem.receivedQuantity;
               
               double newAvgCost = newTotalQty > 0 ? (oldTotalValue + incomingValue) / newTotalQty : product.purchasePrice;
               
               // Update Product
               await txn.update(
                 'products', 
                 {
                   'quantity': newTotalQty,
                   'purchasePrice': newAvgCost, // Update Cost
                   'is_synced': 0
                 },
                 where: 'id = ?',
                 whereArgs: [productId]
               );
             }
             
             if (newReceivedTotal < orderedQty) {
               allFullyReceived = false;
             }
           } else {
             // Check if this item was already fully received or still pending
              final List<Map<String, dynamic>> currentItem = await txn.query('purchase_items', where: 'id = ?', whereArgs: [receivedItem.id]);
              if (currentItem.isNotEmpty) {
                 int r = currentItem.first['receivedQuantity'] as int;
                 int q = currentItem.first['quantity'] as int;
                 if (r < q) allFullyReceived = false;
              }
           }
        }
        
        // Update PO Status
        String newStatus = allFullyReceived ? 'Received' : 'Partial';
        await txn.update('purchase_orders', {'status': newStatus, 'is_synced': 0}, where: 'id = ?', whereArgs: [poId]);
      });
      
      await loadPurchaseOrders();
      Get.back();
      Get.snackbar('Success', 'Items received and inventory updated');
      
      _supabaseService.pushUnsyncedData();
    } catch (e) {
      print('Error receiving items: $e');
      Get.snackbar('Error', 'Failed to receive items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePOStatus(int id, String status) async {
     final db = await _dbHelper.database;
     await db.update('purchase_orders', {'status': status, 'is_synced': 0}, where: 'id = ?', whereArgs: [id]);
     loadPurchaseOrders();
     _supabaseService.pushUnsyncedData();
  }

  Future<void> deletePO(int id) async {
    final db = await _dbHelper.database;
    // Get Supabase ID first
    final List<Map<String, dynamic>> po = await db.query('purchase_orders', columns: ['supabase_id'], where: 'id = ?', whereArgs: [id]);
    String? supabaseId;
    if (po.isNotEmpty) {
      supabaseId = po.first['supabase_id'] as String?;
    }

    await db.delete('purchase_orders', where: 'id = ?', whereArgs: [id]);
    await loadPurchaseOrders();
    
    if (supabaseId != null) {
      await _supabaseService.deleteRow('purchase_orders', supabaseId);
    }
  }
}
