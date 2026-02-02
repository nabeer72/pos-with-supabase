
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
  Future<AuthResponse> signUp(String email, String password) async {
    print('DEBUG: SupabaseService.signUp called for $email');
    return await _supabase.auth.signUp(
      email: email, 
      password: password,
      emailRedirectTo: 'io.supabase.pos://login-callback',
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    print('DEBUG: SupabaseService.signIn called for $email');
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }


  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    print('DEBUG: SupabaseService.getUserProfile called for $email');
    try {
      final response = await _supabase.from('users').select().eq('email', email).maybeSingle();
      print('DEBUG: getUserProfile response: $response');
      return response;
    } catch (e) {
      print('DEBUG: getUserProfile ERROR: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Removes the default trial account from Supabase
  Future<void> cleanupTrialConcepts() async {
    try {
      // Attempt to delete the remote admin demo user if it exists
      await _supabase.from('users').delete().eq('email', 'admin@pos.com');
      print('Remote demo account cleanup attempted.');
    } catch (e) {
      print('Supabase cleanup error (Safe to ignore if admin@pos.com does not exist): $e');
    }
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

    // Don't try to sync if no user is logged in (RLS will block it anyway)
    if (_supabase.auth.currentUser == null) {
      print('Sync skipped: No authenticated user.');
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
            'id': localMap['supabase_id'], // Essential for RLS "insert_self" policy
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
        onConflict: 'name,admin_id', 
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
        onConflict: 'barcode,admin_id', 
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
            'purchase_price': localMap['purchasePrice'] ?? 0.0,
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
        onConflict: 'name,admin_id',
        mapLocalToRemote: (localMap) {
          return {
            'name': localMap['name'],
            'address': localMap['address'],
            'cell_number': localMap['cellNumber'],
            'email': localMap['email'],
            'type': localMap['type'],
            'is_active': localMap['isActive'] == 1,
            'admin_id': localMap['adminId'],
            'discount': localMap['discount'],
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

    // 5.5 Expense Heads
    try {
      await _syncTable(
        'expense_heads', 
        'id', 
        onConflict: 'name,admin_id',
        mapLocalToRemote: (localMap) {
          return {
            'name': localMap['name'],
            'admin_id': localMap['adminId'],
          };
        }
      );
    } catch (e) {
      print('Error syncing expense_heads: $e');
    }

    // 6. Suppliers
    try {
      final db = await _dbHelper.database;
      final unsyncedSuppliers = await db.query('suppliers', where: 'is_synced = 0 OR is_synced IS NULL');
      
      for (var s in unsyncedSuppliers) {
        try {
          // Check if exists
          final existing = await _supabase.from('suppliers')
              .select('id')
              .eq('name', s['name'] as String)
              .eq('admin_id', s['adminId'] as String)
              .maybeSingle();

          dynamic response;
          final data = {
            'name': s['name'],
            'contact': s['contact'],
            'last_order': s['lastOrder'],
            'admin_id': s['adminId'],
          };

          if (existing != null) {
             // Update
             response = await _supabase.from('suppliers').update(data).eq('id', existing['id']).select().single();
          } else {
             // Insert
             response = await _supabase.from('suppliers').insert(data).select().single();
          }
          
          if (response != null) {
            await db.update(
              'suppliers',
              {'is_synced': 1, 'supabase_id': response['id']},
              where: 'id = ?',
              whereArgs: [s['id']]
            );
          }
        } catch (e) {
          print('Error syncing supplier ${s['name']}: $e');
        }
      }
    } catch (e) {
      print('Error iterating suppliers: $e');
    }

    // 7. Settings
    try {
      await _syncTable(
        'settings', 
        'id', 
        onConflict: 'key,admin_id', 
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

    // 8. Loyalty Accounts
    try {
      await _syncTable('loyalty_accounts', 'id', mapLocalToRemote: (localMap) {
        return {
          'customer_id': localMap['customerId'], 
          'total_points': localMap['totalPoints'],
          'cashback_balance': localMap['cashbackBalance'],
          'lifetime_spend': localMap['lifetimeSpend'],
          'admin_id': localMap['adminId'], // Fixed mapping
        };
      }, onConflict: 'customer_id,admin_id');
    } catch (e) {
      print('Error syncing loyalty_accounts: $e');
    }

    // 9. Loyalty Rules
    try {
      await _syncTable('loyalty_rules', 'id', mapLocalToRemote: (localMap) {
        return {
          'points_per_currency_unit': localMap['points_per_currency_unit'],
          'cashback_percentage': localMap['cashback_percentage'],
          'points_expiry_months': localMap['points_expiry_months'],
          'admin_id': localMap['admin_id'],
        };
      }, onConflict: 'admin_id');
    } catch (e) {
      print('Error syncing loyalty_rules: $e');
    }

    // 10. Purchase Orders & Items
    try {
      await _syncPurchaseOrders();
    } catch (e) {
      print('Error syncing purchases: $e');
    }
  }

  Future<void> _syncTable(String tableName, String localIdColumn, {Map<String, dynamic> Function(Map<String, dynamic>)? mapLocalToRemote, String? onConflict}) async {
    final db = await _dbHelper.database;
    final unsyncedRows = await db.query(tableName, where: 'is_synced = 0 OR is_synced IS NULL');

    for (var row in unsyncedRows) {
      try {
        final supabaseId = row['supabase_id'] as String?;
        Map<String, dynamic> dataToSync = mapLocalToRemote != null ? mapLocalToRemote(row) : Map<String, dynamic>.from(row);
        
        if (mapLocalToRemote == null) {
          dataToSync.remove('id');
          dataToSync.remove('is_synced');
          dataToSync.remove('supabase_id');
        }

        dynamic response;
        if (supabaseId != null && tableName != 'users') {
          response = await _supabase.from(tableName).update(dataToSync).eq('id', supabaseId).select().single();
        } else {
          // For users, or when we don't have a supabaseId, we use upsert/insert.
          // For users, supabaseId IS the Auth UUID, so we must upsert it.
          if (onConflict != null || tableName == 'users') {
             response = await _supabase.from(tableName).upsert(dataToSync, onConflict: onConflict ?? 'id').select().single();
          } else {
             response = await _supabase.from(tableName).insert(dataToSync).select().single();
          }
        }

        if (response != null) {
          final newSupabaseId = response['id'];
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
        
        String? customerUuid;
        if (customerId != null) {
          final customer = await db.query('customers', where: 'id = ?', whereArgs: [customerId]);
          if (customer.isNotEmpty && customer.first['supabase_id'] != null) {
            customerUuid = customer.first['supabase_id'] as String;
          }
        }

        final saleData = {
          'sale_date': sale['saleDate'],
          'total_amount': sale['totalAmount'],
          'customer_id': customerUuid, 
          'admin_id': sale['adminId'], 
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

          await _syncSaleItems(sale['id'] as int, newSupabaseId);
        }
      } catch (e) {
        print('Error syncing sale ${sale['id']}: $e');
      }
    }
  }

  Future<void> _syncSaleItems(int localSaleId, String remoteSaleId) async {
    final db = await _dbHelper.database;
    final items = await db.query('sale_items', where: 'saleId = ?', whereArgs: [localSaleId]);

    for (var item in items) {
       if (item['is_synced'] == 1) continue;

       try {
         final productId = item['productId'] as int;
         final product = await db.query('products', where: 'id = ?', whereArgs: [productId]);
         String? productUuid;
         if (product.isNotEmpty) {
           productUuid = product.first['supabase_id'] as String?;
         }

         if (productUuid == null) continue; 

         final itemData = {
           'sale_id': remoteSaleId,
           'product_id': productUuid,
           'quantity': item['quantity'],
           'unit_price': item['unitPrice'],
           'admin_id': item['adminId'], 
         };

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

  Future<void> _syncPurchaseOrders() async {
    final db = await _dbHelper.database;
    final unsyncedPOs = await db.query('purchase_orders', where: 'is_synced = 0 OR is_synced IS NULL');

    for (var po in unsyncedPOs) {
      try {
        final supabaseId = po['supabase_id'] as String?;
        final supplierId = po['supplierId'] as int?;
        
        String? supplierUuid;
        if (supplierId != null) {
          final supplier = await db.query('suppliers', where: 'id = ?', whereArgs: [supplierId]);
          if (supplier.isNotEmpty) {
             supplierUuid = supplier.first['supabase_id'] as String?;
          }
        }

        final poData = {
          'supplier_id': supplierUuid,
          'order_date': po['orderDate'],
          'expected_date': po['expectedDate'],
          'status': po['status'],
          'total_amount': po['totalAmount'],
          'notes': po['notes'],
          'invoice_number': po['invoice_number'],
          'payment_type': po['payment_type'],
          'bank_name': po['bank_name'],
          'cheque_number': po['cheque_number'],
          'admin_id': po['adminId'], 
        };

        dynamic response;
        if (supabaseId != null) {
          response = await _supabase.from('purchase_orders').update(poData).eq('id', supabaseId).select().single();
        } else {
          response = await _supabase.from('purchase_orders').insert(poData).select().single();
        }

        if (response != null) {
           final newSupabaseId = response['id'];
           await db.update(
             'purchase_orders',
             {'is_synced': 1, 'supabase_id': newSupabaseId},
             where: 'id = ?',
             whereArgs: [po['id']],
           );
           
           await _syncPurchaseItems(po['id'] as int, newSupabaseId);
        }
      } catch (e) {
        print('Error syncing PO ${po['id']}: $e');
      }
    }
  }

  Future<void> _syncPurchaseItems(int localPOId, String remotePOId) async {
    final db = await _dbHelper.database;
    final items = await db.query('purchase_items', where: 'purchaseId = ?', whereArgs: [localPOId]);
    
    for (var item in items) {
      if (item['is_synced'] == 1 && item['supabase_id'] != null) continue; 
      
      try {
         final productId = item['productId'] as int;
         final product = await db.query('products', where: 'id = ?', whereArgs: [productId]);
         String? productUuid;
         if (product.isNotEmpty) {
           productUuid = product.first['supabase_id'] as String?;
         }
         
         if (productUuid == null) continue;

         final itemData = {
           'purchase_id': remotePOId,
           'product_id': productUuid,
           'quantity': item['quantity'],
           'received_quantity': item['receivedQuantity'],
           'unit_cost': item['unitCost'],
           'selling_price': item['selling_price'],
           'admin_id': item['adminId'],
         };

         dynamic response;
         if (item['supabase_id'] != null) {
           response = await _supabase.from('purchase_items').update(itemData).eq('id', item['supabase_id']!).select().single();
         } else {
           response = await _supabase.from('purchase_items').insert(itemData).select().single();
         }
         
         if (response != null) {
           await db.update(
             'purchase_items',
             {'is_synced': 1, 'supabase_id': response['id']},
             where: 'id = ?',
             whereArgs: [item['id']]
           );
         }
      } catch (e) {
        print('Error syncing PO item ${item['id']}: $e');
      }
    }
  }

  Future<void> pullRemoteData() async {
    final authController = Get.find<AuthController>();
    final adminId = authController.adminId;
    if (adminId == null) return;
    
    print('Starting full remote data pull for admin: $adminId');

    final db = await _dbHelper.database;

    // Pull Categories
    try {
      print('Pulling categories...');
      final remoteCategories = await _supabase.from('categories').select().eq('admin_id', adminId);
      for (var cat in remoteCategories) {
        final localCat = await db.query('categories', where: 'supabase_id = ?', whereArgs: [cat['id']]);
        final int? existingId = localCat.isNotEmpty ? localCat.first['id'] as int? : null;
        
        await db.insert('categories', {
          'id': existingId,
          'name': cat['name'],
          'adminId': adminId,
          'supabase_id': cat['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling categories: $e');
    }

    // Pull Products
    try {
      print('Pulling products...');
      final remoteProducts = await _supabase.from('products').select().eq('admin_id', adminId);
      for (var p in remoteProducts) {
        // Safety check: Don't overwrite if local product has unsynced changes
        final localProduct = await db.query(
          'products', 
          where: 'supabase_id = ?', 
          whereArgs: [p['id']]
        );
        
        if (localProduct.isNotEmpty && localProduct.first['is_synced'] == 0) {
          print('Skipping product ${p['name']} because it has unsynced local changes');
          continue;
        }

        final int? existingId = localProduct.isNotEmpty ? localProduct.first['id'] as int? : null;

        await db.insert('products', {
          'id': existingId, // Preserve local ID
          'name': p['name'],
          'barcode': p['barcode'],
          'price': p['price'],
          'category': p['category'],
          'quantity': p['quantity'],
          'color': p['color'],
          'icon': p['icon'],
          'purchasePrice': p['purchase_price'] ?? 0.0,
          'adminId': adminId,
          'supabase_id': p['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling products: $e');
    }

    // Pull Customers
    try {
      print('Pulling customers...');
      final remoteCustomers = await _supabase.from('customers').select().eq('admin_id', adminId);
      for (var c in remoteCustomers) {
        final localCust = await db.query('customers', where: 'supabase_id = ?', whereArgs: [c['id']]);
        
        if (localCust.isNotEmpty && localCust.first['is_synced'] == 0) continue;
        
        final int? existingId = localCust.isNotEmpty ? localCust.first['id'] as int? : null;

        await db.insert('customers', {
          'id': existingId,
          'name': c['name'],
          'address': c['address'],
          'cellNumber': c['cell_number'],
          'email': c['email'],
           'type': c['type'],
          'isActive': c['is_active'] == true ? 1 : 0,
          'adminId': adminId,
          'supabase_id': c['id'],
          'is_synced': 1,
          'discount': (c['discount'] as num?)?.toDouble() ?? 0.0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling customers: $e');
    }

    // Pull Sales
    try {
      print('Pulling sales...');
      final remoteSales = await _supabase.from('sales').select().eq('admin_id', adminId);
      for (var s in remoteSales) {
        final localSale = await db.query('sales', where: 'supabase_id = ?', whereArgs: [s['id']]);
        if (localSale.isNotEmpty && localSale.first['is_synced'] == 0) continue;
        final int? existingId = localSale.isNotEmpty ? localSale.first['id'] as int? : null;

        int localSaleId = await db.insert('sales', {
          'id': existingId,
          'saleDate': s['sale_date'],
          'totalAmount': s['total_amount'],
          'customerId': null, 
          'adminId': adminId,
          'supabase_id': s['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        if (localSaleId > 0) {
          final remoteItems = await _supabase.from('sale_items').select().eq('sale_id', s['id']);
          for (var item in remoteItems) {
            final remoteProductId = item['product_id'];
            final localProduct = await db.query('products', where: 'supabase_id = ?', whereArgs: [remoteProductId]);
            
            if (localProduct.isNotEmpty) {
              final localItem = await db.query('sale_items', where: 'supabase_id = ?', whereArgs: [item['id']]);
              final int? existingId = localItem.isNotEmpty ? localItem.first['id'] as int? : null;

              await db.insert('sale_items', {
                'id': existingId,
                'saleId': localSaleId, 
                'productId': localProduct.first['id'],
                'quantity': item['quantity'],
                'unitPrice': item['unit_price'],
                'adminId': adminId,
                'supabase_id': item['id'],
                'is_synced': 1
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      }
    } catch (e) {
      print('Error pulling sales: $e');
    }

    // Pull Expenses
    try {
      print('Pulling expenses...');
      final remoteExpenses = await _supabase.from('expenses').select().eq('admin_id', adminId);
      for (var exp in remoteExpenses) {
        await db.insert('expenses', {
          'category': exp['category'],
          'amount': exp['amount'],
          'date': exp['date'],
          'adminId': adminId,
          'supabase_id': exp['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling expenses: $e');
    }

    // Pull Expense Heads
    try {
      print('Pulling expense heads...');
      final remoteHeads = await _supabase.from('expense_heads').select().eq('admin_id', adminId);
      for (var head in remoteHeads) {
        await db.insert('expense_heads', {
          'name': head['name'],
          'adminId': adminId,
          'supabase_id': head['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling expense heads: $e');
    }

    // Pull Loyalty Rules
    try {
      print('Pulling loyalty rules...');
      final remoteRules = await _supabase.from('loyalty_rules').select().eq('admin_id', adminId);
      for (var rule in remoteRules) {
        await db.insert('loyalty_rules', {
          'points_per_currency_unit': rule['points_per_currency_unit'],
          'cashback_percentage': rule['cashback_percentage'],
          'points_expiry_months': rule['points_expiry_months'],
          'admin_id': adminId,
          'supabase_id': rule['id'],
          'is_synced': 1
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling loyalty rules: $e');
    }

    // Pull Suppliers
    try {
      print('Pulling suppliers...');
      final remoteSuppliers = await _supabase.from('suppliers').select().eq('admin_id', adminId);
      for (var s in remoteSuppliers) {
         await db.insert('suppliers', {
           'name': s['name'],
           'contact': s['contact'],
           'lastOrder': s['last_order'],
           'adminId': adminId,
           'supabase_id': s['id'],
           'is_synced': 1
         }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      print('Error pulling suppliers: $e');
    }
    
    // Pull Purchase Orders
    try {
      print('Pulling purchase orders...');
      final remotePOs = await _supabase.from('purchase_orders').select().eq('admin_id', adminId);
      for (var po in remotePOs) {
         int? localSupplierId;
         if (po['supplier_id'] != null) {
           final localSupp = await db.query('suppliers', where: 'supabase_id = ?', whereArgs: [po['supplier_id']]);
           if (localSupp.isNotEmpty) localSupplierId = localSupp.first['id'] as int;
         }

         int localPOId = await db.insert('purchase_orders', {
           'supplierId': localSupplierId,
           'orderDate': po['order_date'],
           'expectedDate': po['expected_date'],
           'status': po['status'],
           'totalAmount': po['total_amount'],
           'notes': po['notes'],
           'invoice_number': po['invoice_number'],
           'payment_type': po['payment_type'],
           'bank_name': po['bank_name'],
           'cheque_number': po['cheque_number'],
           'adminId': adminId,
           'supabase_id': po['id'],
           'is_synced': 1
         }, conflictAlgorithm: ConflictAlgorithm.replace);
         
         if (localPOId > 0) {
            final remoteItems = await _supabase.from('purchase_items').select().eq('purchase_id', po['id']);
            for (var item in remoteItems) {
               final localProduct = await db.query('products', where: 'supabase_id = ?', whereArgs: [item['product_id']]);
               if (localProduct.isNotEmpty) {
                 await db.insert('purchase_items', {
                   'purchaseId': localPOId,
                   'productId': localProduct.first['id'],
                   'quantity': item['quantity'],
                   'receivedQuantity': item['received_quantity'],
                   'unitCost': item['unit_cost'],
                   'selling_price': item['selling_price'],
                   'adminId': adminId,
                   'supabase_id': item['id'],
                   'is_synced': 1
                 }, conflictAlgorithm: ConflictAlgorithm.replace);
               }
            }
         }
      }
    } catch (e) {
      print('Error pulling purchases: $e');
    }
    
    print('Remote data pull completed.');
  }
  Future<void> deleteRow(String tableName, String supabaseId) async {
    try {
      await _supabase.from(tableName).delete().eq('id', supabaseId);
    } catch (e) {
      print('Error deleting $tableName row $supabaseId: $e');
    }
  }
}

