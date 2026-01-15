import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/Services/database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
      await pullRemoteData();
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> pushUnsyncedData() async {
    // 0. Users (Sync first so foreign keys might work if needed, though usually unrelated)
    await _syncTable(
      'users', 
      'id', 
      onConflict: 'email', // Handle duplicate emails by updating
      mapLocalToRemote: (localMap) {
        return {
          'name': localMap['name'],
          'email': localMap['email'],
          'role': localMap['role'],
          'permissions': localMap['permissions'],
          'last_active': localMap['lastActive'], // Mapped to snake_case for Supabase
          'password': localMap['password'], // Syncing password as requested
        };
      }
    );

    // 1. Categories
    await _syncTable(
      'categories', 
      'name',
      onConflict: 'name', // Fix duplicate key error
      mapLocalToRemote: (localMap) {
        return {
          'name': localMap['name'],
        };
      }
    ); 
    
    // 2. Products
    await _syncTable('products', 'id', mapLocalToRemote: (localMap) {
      // Fix: Cast color/icon to 32-bit signed int for Postgres 'integer' compatibility
      // Dart ints are 64-bit, so large 32-bit unsigned values (like colors 0xFF...) 
      // appear as large positives that overflow Postgres signed 4-byte integer.
      // .toSigned(32) converts them to negative numbers if needed, which fit.
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
        // 'purchase_price': localMap['purchasePrice'] ?? 0.0, // TODO: Uncomment when column is added to Supabase
      };
    });

    // 3. Customers
    await _syncTable('customers', 'id', mapLocalToRemote: (localMap) {
      return {
        'name': localMap['name'],
        'address': localMap['address'],
        'cellNumber': localMap['cellNumber'],
        'email': localMap['email'],
        'type': localMap['type'],
        'isActive': localMap['isActive'],
      };
    });

    // 4. Sales & SaleItems
    // Sales need to be synced first, then items with valid sale_id (UUID)
    await _syncSales();
    
    // 5. Expenses
    await _syncTable('expenses', 'id', mapLocalToRemote: (localMap) {
      return {
        'category': localMap['category'],
        'amount': localMap['amount'],
        'date': localMap['date'],
      };
    });

    // 6. Suppliers
    await _syncTable('suppliers', 'id', mapLocalToRemote: (localMap) {
      return {
        'name': localMap['name'],
        'contact': localMap['contact'],
        'lastOrder': localMap['lastOrder'],
      };
    });

    // 7. Settings (Currency and other preferences)
    await _syncTable('settings', 'id', mapLocalToRemote: (localMap) {
      return {
        'key': localMap['key'],
        'value': localMap['value'],
        'admin_id': localMap['adminId'],
      };
    });
  }

  Future<void> _syncTable(String tableName, String localIdColumn, {Map<String, dynamic> Function(Map<String, dynamic>)? mapLocalToRemote, String? onConflict}) async {
    final db = await _dbHelper.database;
    final unsyncedRows = await db.query(tableName, where: 'is_synced = 0');

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
    final unsyncedSales = await db.query('sales', where: 'is_synced = 0');

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
    // This requires implementing logic to fetch data from Supabase and `upsert` locally.
    // For simplicity in this iteration, we focus on PUSH (Offline -> Online).
    // Pulling data implies conflict resolution. 
    // We can implement a simple pull for products/categories if they are managed elsewhere.
  }
  Future<void> deleteRow(String tableName, String supabaseId) async {
    try {
      await _supabase.from(tableName).delete().eq('id', supabaseId);
    } catch (e) {
      print('Error deleting $tableName row $supabaseId: $e');
    }
  }
}
