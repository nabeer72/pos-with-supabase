import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import 'package:pos/Services/Controllers/auth_controller.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;
  final _dbHelper = DatabaseHelper();

  // Configuration
  static const String supabaseUrl = 'https://gxiftmvrnieqdsmdcwhz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4aWZ0bXZybmllcWRzbWRjd2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5MzYxMTQsImV4cCI6MjA4MzUxMjExNH0.43rUqJARm04tLrnDtgeW8KzUONNwl7iECspyHQFb3cc';


  // Auth Methods
  // Auth Methods
  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      final response = await _supabase.from('users').select().eq('email', email).single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  Future<void> syncData() async {
    // Check internet connection
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return;
    }

    try {
      await pushUnsyncedData();
    } catch (e) {
      print('Push sync error: $e');
    }
    
    try {
      await pullRemoteData();
    } catch (e) {
      print('Pull sync error: $e');
    }
  }

  Future<void> pushUnsyncedData() async {
    // 0. Users
    try {
      await _syncTable(
        'users', 
        'id', 
        onConflict: 'email', 
        mapLocalToRemote: (localMap) {
          return {
            'name': localMap['name'],
            'email': localMap['email'],
            'role': localMap['role'],
            'permissions': localMap['permissions'],
            'last_active': localMap['lastActive'],
            'password': localMap['password'],
            'admin_id': localMap['adminId'],
          };
        }
      );
    } catch (e) {
      print('Error syncing users: $e');
    }

    // 1. Categories
    try {
      await _syncTable(
        'categories', 
        'id',
        onConflict: 'name,admin_id', // Handle composite unique constraint
        mapLocalToRemote: (localMap) {
          return {
            'name': localMap['name'],
            'admin_id': localMap['adminId'],
          };
        }
      );
    } catch (e) {
      print('Error syncing categories: $e');
    }
    
    // 2. Products
    try {
      await _syncTable(
        'products', 
        'id', 
        onConflict: 'barcode,admin_id', // Handle barcode collision for the same admin
        mapLocalToRemote: (localMap) {
          int colorVal = localMap['color'] ?? 0;
          int iconVal = localMap['icon'] ?? 0;

          return {
            'name': localMap['name'],
            'price': localMap['price'],
            'category': localMap['category'], 
            'quantity': localMap['quantity'],
            'barcode': localMap['barcode'],
            'color': colorVal.toSigned(32),
            'icon': iconVal.toSigned(32),
            'admin_id': localMap['adminId'],
            'purchasePrice': localMap['purchasePrice'] ?? 0.0,
          };
        }
      );
    } catch (e) {
      print('Error syncing products: $e');
    }

    // 3. Customers
    try {
      await _syncTable(
        'customers', 
        'id', 
        onConflict: 'name,admin_id', // Handle name collision for the same admin
        mapLocalToRemote: (localMap) {
          return {
            'name': localMap['name'],
            'address': localMap['address'],
            'cellNumber': localMap['cellNumber'],
            'email': localMap['email'],
            'type': localMap['type'],
            'isActive': localMap['isActive'],
            'admin_id': localMap['adminId'],
          };
        }
      );
    } catch (e) {
      print('Error syncing customers: $e');
    }

    // 4. Sales & SaleItems
    try {
      await _syncSales();
    } catch (e) {
      print('Error syncing sales: $e');
    }
    
    // 5. Expenses
    try {
      await _syncTable('expenses', 'id', mapLocalToRemote: (localMap) {
        return {
          'category': localMap['category'],
          'amount': localMap['amount'],
          'date': localMap['date'],
          'admin_id': localMap['adminId'],
        };
      });
    } catch (e) {
      print('Error syncing expenses: $e');
    }

    // 6. Suppliers
    try {
      await _syncTable(
        'suppliers', 
        'id', 
        onConflict: 'name,admin_id',
        mapLocalToRemote: (localMap) {
          return {
            'name': localMap['name'],
            'contact': localMap['contact'],
            'lastOrder': localMap['lastOrder'],
            'admin_id': localMap['adminId'],
          };
        }
      );
    } catch (e) {
      print('Error syncing suppliers: $e');
    }

    // 7. Settings
    try {
      await _syncTable(
        'settings', 
        'id', 
        onConflict: 'key,admin_id', // Fix duplicate key error for settings
        mapLocalToRemote: (localMap) {
          return {
            'key': localMap['key'],
            'value': localMap['value'],
            'admin_id': localMap['adminId'],
          };
        }
      );
    } catch (e) {
      print('Error syncing settings: $e');
    }
  }

  Future<void> _syncTable(String tableName, String localIdColumn, {Map<String, dynamic> Function(Map<String, dynamic>)? mapLocalToRemote, String? onConflict}) async {
    final db = await _dbHelper.database;
    final unsyncedRows = await db.query(tableName, where: 'is_synced = 0 OR is_synced IS NULL');

    for (var row in unsyncedRows) {
      try {
        final supabaseId = row['supabase_id'] as String?;
        Map<String, dynamic> dataToSync = mapLocalToRemote != null ? mapLocalToRemote(row) : Map<String, dynamic>.from(row);
        
        // Remove local-only fields if copying all
        if (mapLocalToRemote == null) {
          dataToSync.remove('id'); // Local ID
          dataToSync.remove('is_synced');
          dataToSync.remove('supabase_id');
        }

        dynamic response;
        if (supabaseId != null) {
          // Update existing
          response = await _supabase.from(tableName).update(dataToSync).eq('id', supabaseId).select().single();
        } else {
          // Insert new or Upsert
          if (onConflict != null) {
             response = await _supabase.from(tableName).upsert(dataToSync, onConflict: onConflict).select().single();
          } else {
             response = await _supabase.from(tableName).insert(dataToSync).select().single();
          }
        }

        if (response != null) {
          final newSupabaseId = response['id'];
          // Update local record
          await db.update(
            tableName,
            {'is_synced': 1, 'supabase_id': newSupabaseId},
            where: '$localIdColumn = ?',
            whereArgs: [row[localIdColumn]],
          );
        }
      } catch (e) {
        print('Error syncing $tableName row ${row[localIdColumn]}: $e');
      }
    }
  }

  Future<void> _syncSales() async {
    final db = await _dbHelper.database;
    final unsyncedSales = await db.query('sales', where: 'is_synced = 0 OR is_synced IS NULL');

    for (var sale in unsyncedSales) {
      try {
        final supabaseId = sale['supabase_id'] as String?;
        final customerId = sale['customerId'] as int?;
        
        // Resolve Customer UUID if needed
        String? customerUuid;
        if (customerId != null) {
          final customer = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
          if (customer.isNotEmpty && customer.first['supabase_id'] != null) {
            customerUuid = customer.first['supabase_id'] as String;
          }
        }

        final saleData = {
          'saleDate': sale['saleDate'],
          'totalAmount': sale['totalAmount'],
          'customer_id': customerUuid, // Assuming remote column is customer_id
          'admin_id': sale['adminId'], // Added admin_id
        };

        dynamic response;
        if (supabaseId != null) {
          response = await _supabase.from('sales').update(saleData).eq('id', supabaseId).select().single();
        } else {
          response = await _supabase.from('sales').insert(saleData).select().single();
        }

        if (response != null) {
          final newSupabaseId = response['id'];
          
          await db.update(
            'sales',
            {'is_synced': 1, 'supabase_id': newSupabaseId},
            where: 'id = ?',
            whereArgs: [sale['id']],
          );

          // Now sync items for this sale
          await _syncSaleItems(sale['id'] as int, newSupabaseId);
        }
      } catch (e) {
        print('Error syncing sale ${sale['id']}: $e');
      }
    }
  }

  Future<void> _syncSaleItems(int localSaleId, String remoteSaleId) async {
    final db = await _dbHelper.database;
    // We sync all items for this sale that are not synced (or all of them if we treat sale + items as unit)
    // Actually items might be added later? Assuming sale creation includes items.
    final items = await db.query('sale_items', where: 'saleId = ?', whereArgs: [localSaleId]);

    for (var item in items) {
       if (item['is_synced'] == 1) continue;

       try {
         // Resolve Product UUID
         final productId = item['productId'] as int;
         final product = await db.query('products', where: 'id = ?', whereArgs: [productId]);
         String? productUuid;
         if (product.isNotEmpty) {
           productUuid = product.first['supabase_id'] as String?;
         }

         if (productUuid == null) {
            // Product not synced yet? Should have been synced by _syncTable('products') earlier.
            // If not, we might fail constraint. Skip or force sync product? 
            // For now, continue. Database constraints on Supabase might fail.
            continue; 
         }

         final itemData = {
           'sale_id': remoteSaleId,
           'product_id': productUuid,
           'quantity': item['quantity'],
           'unitPrice': item['unitPrice'],
           'admin_id': item['adminId'], // Added admin_id
         };

         // Insert item (items typically not updated individually in this POS context, but handled as part of sale)
         final response = await _supabase.from('sale_items').insert(itemData).select().single();
         
         if (response != null) {
           await db.update(
             'sale_items',
             {'is_synced': 1, 'supabase_id': response['id']},
             where: 'id = ?',
             whereArgs: [item['id']],
           );
         }

       } catch (e) {
         print('Error syncing sale item ${item['id']}: $e');
       }
    }
  }

  Future<void> pullRemoteData() async {
    final authController = Get.find<AuthController>();
    final adminId = authController.adminId;
    if (adminId == null) return;

    final db = await _dbHelper.database;

    // Pull Categories
    try {
      final remoteCategories = await _supabase.from('categories').select().eq('admin_id', adminId);
      for (var cat in remoteCategories) {
        await db.insert('categories', {
          'name': cat['name'],
          'adminId': adminId,
          'supabase_id': cat['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace); // Use replace to update supabase_id if name matches
      }
    } catch (e) {
      print('Error pulling categories: $e');
    }

    // Pull Products
    try {
      final remoteProducts = await _supabase.from('products').select().eq('admin_id', adminId);
      for (var p in remoteProducts) {
        await db.insert('products', {
          'name': p['name'],
          'barcode': p['barcode'],
          'price': p['price'],
          'category': p['category'],
          'quantity': p['quantity'],
          'color': p['color'],
          'icon': p['icon'],
          'purchasePrice': p['purchasePrice'] ?? 0.0,
          'adminId': adminId,
          'supabase_id': p['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace); // Use replace to link local by barcode
      }
    } catch (e) {
      print('Error pulling products: $e');
    }

    // Pull Customers
    try {
      final remoteCustomers = await _supabase.from('customers').select().eq('admin_id', adminId);
      for (var c in remoteCustomers) {
        await db.insert('customers', {
          'name': c['name'],
          'address': c['address'],
          'cellNumber': c['cellNumber'],
          'email': c['email'],
          'type': c['type'],
          'isActive': c['isActive'],
          'adminId': adminId,
          'supabase_id': c['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace); // Use replace to link local by name
      }
    } catch (e) {
      print('Error pulling customers: $e');
    }

    // Pull Sales
    try {
      final remoteSales = await _supabase.from('sales').select().eq('admin_id', adminId);
      for (var s in remoteSales) {
        int localSaleId = await db.insert('sales', {
          'saleDate': s['saleDate'],
          'totalAmount': s['totalAmount'],
          'customerId': null, 
          'adminId': adminId,
          'supabase_id': s['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace); // Use replace based on supabase_id unique index

        if (localSaleId > 0) {
          // Pull and link sale items
          final remoteItems = await _supabase.from('sale_items').select().eq('sale_id', s['id']);
          for (var item in remoteItems) {
            // Resolve local product ID from remote product UUID
            final remoteProductId = item['product_id'];
            final localProduct = await db.query('products', where: 'supabase_id = ?', whereArgs: [remoteProductId]);
            
            if (localProduct.isNotEmpty) {
              await db.insert('sale_items', {
                'saleId': localSaleId,
                'productId': localProduct.first['id'],
                'quantity': item['quantity'],
                'unitPrice': item['unitPrice'],
                'adminId': adminId,
                'supabase_id': item['id'],
                'is_synced': 1
              }, conflictAlgorithm: ConflictAlgorithm.replace); // Use replace based on supabase_id
            }
          }
        }
      }
    } catch (e) {
      print('Error pulling sales: $e');
    }
  }
  Future<void> deleteRow(String tableName, String supabaseId) async {
    try {
      await _supabase.from(tableName).delete().eq('id', supabaseId);
    } catch (e) {
      print('Error deleting $tableName row $supabaseId: $e');
    }
  }
}
