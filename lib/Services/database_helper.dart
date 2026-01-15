import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos/Services/models/product_model.dart';
import 'package:pos/Services/models/customer_model.dart';
import 'package:pos/Services/models/sale_model.dart';
import 'package:pos/Services/models/sale_item_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _databaseVersion = 11;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    final db = await openDatabase(
      path,
      version: _databaseVersion, // Use the version constant
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return db;
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      await _seedCategories(db, '1');
    }
    if (oldVersion < 3) {
      // Ensure users table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          role TEXT NOT NULL,
          lastActive TEXT NOT NULL
        )
      ''');

      // Check for columns before adding
      var tableInfo = await db.rawQuery('PRAGMA table_info(users)');
      var columns = tableInfo.map((e) => e['name']).toList();
      
      if (!columns.contains('email')) {
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      }
      if (!columns.contains('password')) {
        await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
      }
      if (!columns.contains('permissions')) {
        await db.execute('ALTER TABLE users ADD COLUMN permissions TEXT');
      }
      
      // Seed default admin if not exists
      final List<Map<String, dynamic>> admins = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: ['admin@pos.com'],
      );
      
      if (admins.isEmpty) {
        // Insert the admin user and get its ID
        final int adminUserId = await db.insert('users', {
          'name': 'Admin',
          'role': 'Admin',
          'lastActive': DateTime.now().toString(),
          'email': 'admin@pos.com',
          'password': 'adminpassword',
          'permissions': '["all"]'
        });

        // Update the adminId column for this user to be its own ID
        final String adminId = adminUserId.toString();
        await db.update(
          'users',
          {'adminId': adminId},
          where: 'id = ?',
          whereArgs: [adminUserId],
        );
        
        // Seed default categories for this new admin
        await _seedCategories(db, adminId);
      }
    }
    if (oldVersion < 4) {
      var tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      var columns = tableInfo.map((e) => e['name']).toList();
      if (!columns.contains('barcode')) {
        await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
      }
      }
    
    if (oldVersion < 5) {
      // Add supabase_id and is_synced columns to all tables
      List<String> tables = [
        'products', 'customers', 'sales', 'sale_items', 'expenses', 'suppliers', 'categories', 'users'
      ];
      
      for (var table in tables) {
        var tableInfo = await db.rawQuery('PRAGMA table_info($table)');
        var columns = tableInfo.map((e) => e['name']).toList();
        
        if (!columns.contains('supabase_id')) {
          await db.execute('ALTER TABLE $table ADD COLUMN supabase_id TEXT');
        }
        if (!columns.contains('is_synced')) {
          await db.execute('ALTER TABLE $table ADD COLUMN is_synced INTEGER DEFAULT 0');
        }
      }
    }

    if (oldVersion < 6) {
      // Add is_favorite column to products
      var tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      var columns = tableInfo.map((e) => e['name']).toList();
      if (!columns.contains('is_favorite')) {
        await db.execute('ALTER TABLE products ADD COLUMN is_favorite INTEGER DEFAULT 0');
      }
    }

    if (oldVersion < 7) {
      // Add purchasePrice column to products
      var tableInfo = await db.rawQuery('PRAGMA table_info(products)');
      var columns = tableInfo.map((e) => e['name']).toList();
      if (!columns.contains('purchasePrice')) {
        await db.execute('ALTER TABLE products ADD COLUMN purchasePrice REAL DEFAULT 0.0');
      }
    }


    if (oldVersion < 8) {
      // Add adminId column to enforce multi-tenancy
      await db.execute('ALTER TABLE products ADD COLUMN adminId TEXT');
      await db.execute('ALTER TABLE categories ADD COLUMN adminId TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN adminId TEXT');
    }

    if (oldVersion < 9) {
      // Migrate settings table to support admin-specific settings
      // Since we can't easily alter the primary key, we'll recreate the table
      await db.execute('ALTER TABLE settings RENAME TO settings_old');
      
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL,
          value TEXT,
          adminId TEXT,
          UNIQUE(key, adminId)
        )
      ''');
      
      // Migrate old data (assign to admin '1' as default)
      await db.execute('''
        INSERT INTO settings (key, value, adminId)
        SELECT key, value, '1' FROM settings_old
      ''');
      
      await db.execute('DROP TABLE settings_old');
      
      // Initialize default currency for existing admin
      await db.insert('settings', {
        'key': 'currency',
        'value': 'USD',
        'adminId': '1'
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (oldVersion < 10) {
      // Add adminId column to all remaining tables for complete isolation
      List<String> tables = [
        'customers', 'sales', 'sale_items', 'expenses', 'suppliers'
      ];
      
      for (var table in tables) {
        var tableInfo = await db.rawQuery('PRAGMA table_info($table)');
        var columns = tableInfo.map((e) => e['name']).toList();
        
        if (!columns.contains('adminId')) {
          await db.execute('ALTER TABLE $table ADD COLUMN adminId TEXT');
        }
      }

      // Migrate existing data to default admin '1'
      for (var table in tables) {
        await db.execute('UPDATE $table SET adminId = ? WHERE adminId IS NULL', ['1']);
      }
    }

    if (oldVersion < 11) {
      // Add sync columns to settings table
      var tableInfo = await db.rawQuery('PRAGMA table_info(settings)');
      var columns = tableInfo.map((e) => e['name']).toList();
      
      if (!columns.contains('is_synced')) {
        await db.execute('ALTER TABLE settings ADD COLUMN is_synced INTEGER DEFAULT 0');
      }
      if (!columns.contains('supabase_id')) {
        await db.execute('ALTER TABLE settings ADD COLUMN supabase_id TEXT');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        icon INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        color INTEGER,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        purchasePrice REAL DEFAULT 0.0,
        adminId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        cellNumber TEXT,
        email TEXT,
        type INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        customerId INTEGER,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT,
        FOREIGN KEY (saleId) REFERENCES sales (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        lastOrder TEXT NOT NULL,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL,
        value TEXT,
        adminId TEXT,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        UNIQUE(key, adminId)
      )
    ''');
    
    // Initialize last backup date
    await db.insert('settings', {'key': 'last_backup_date', 'value': ''});

    // Seed default categories for default admin
    await _seedCategories(db, '1');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        lastActive TEXT NOT NULL,
        email TEXT UNIQUE,
        password TEXT,
        permissions TEXT,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0,
        adminId TEXT
      )
    ''');

    // Seed initial users
    await db.insert('users', {
      'name': 'Admin', 
      'role': 'Admin', 
      'lastActive': 'Oct 18, 2025',
      'email': 'admin@pos.com',
      'password': 'adminpassword',
      'permissions': '["all"]',
      'adminId': '1'
    });
    await db.insert('users', {
      'name': 'Jane Smith', 
      'role': 'Cashier', 
      'lastActive': 'Oct 17, 2025',
      'email': 'jane@pos.com',
      'password': 'password123',
      'permissions': '["sales", "customers", "reports"]',
      'adminId': '1'
    });
  }

  Future<void> seedCategoriesForAdmin(String adminId) async {
    Database db = await database;
    await _seedCategories(db, adminId);
  }

  Future<void> _seedCategories(Database db, String adminId) async {
    final List<String> defaultCategories = [
      'Electronics',
      'Clothing',
      'Accessories',
      'Groceries',
      'Home & Kitchen',
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', {'name': cat, 'adminId': adminId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // Generic CRUD operations can be added here or specialized methods
  
  // Products
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts({String? adminId}) async {
    Database db = await database;
    final String? whereClause = adminId != null ? 'adminId = ?' : null;
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;

    final List<Map<String, dynamic>> maps = await db.query('products', where: whereClause, whereArgs: whereArgs);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    Database db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getFavoriteProducts({String? adminId}) async {
    Database db = await database;
    final String whereClause = adminId != null ? 'is_favorite = 1 AND adminId = ?' : 'is_favorite = 1';
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Customers
  Future<int> insertCustomer(CustomerModel customer) async {
    Database db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<CustomerModel>> getCustomers({String? adminId}) async {
    Database db = await database;
    final String? whereClause = adminId != null ? 'adminId = ?' : null;
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;
    final List<Map<String, dynamic>> maps = await db.query('customers', where: whereClause, whereArgs: whereArgs);
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    Database db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Expenses
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses({String? adminId}) async {
    Database db = await database;
    final String? whereClause = adminId != null ? 'adminId = ?' : null;
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;
    return await db.query('expenses', where: whereClause, whereArgs: whereArgs);
  }

  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    Database db = await database;
    return await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    Database db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Suppliers
  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    Database db = await database;
    return await db.insert('suppliers', supplier);
  }

  Future<List<Map<String, dynamic>>> getSuppliers({String? adminId}) async {
    Database db = await database;
    final String? whereClause = adminId != null ? 'adminId = ?' : null;
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;
    return await db.query('suppliers', where: whereClause, whereArgs: whereArgs);
  }

  Future<int> updateSupplier(int id, Map<String, dynamic> supplier) async {
    Database db = await database;
    return await db.update(
      'suppliers',
      supplier,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    Database db = await database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Categories
  Future<int> insertCategory(String name, {String? adminId}) async {
    Database db = await database;
    return await db.insert('categories', {'name': name, 'adminId': adminId}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCategories({String? adminId}) async {
    Database db = await database;
    final String? whereClause = adminId != null ? 'adminId = ?' : null;
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;

    final List<Map<String, dynamic>> maps = await db.query('categories', where: whereClause, whereArgs: whereArgs);
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  Future<int> deleteCategory(String name) async {
    Database db = await database;
    return await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  // Sales
  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    Database db = await database;
    return await db.transaction((txn) async {
      int saleId = await txn.insert('sales', sale.toMap());
      for (var item in items) {
        await txn.insert('sale_items', {
          ...item.toMap(),
          'saleId': saleId,
          'adminId': sale.adminId, // Ensure items have the same adminId
        });
        
        // Update product quantity (should only affect admin's product, though ID is unique)
        await txn.execute(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      return saleId;
    });
  }

  Future<Map<String, dynamic>> getSalesSummary({String? adminId}) async {
    Database db = await database;
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    String query = 'SELECT SUM(totalAmount) as totalAmount, COUNT(*) as totalCount FROM sales WHERE saleDate LIKE ?';
    List<Object?> args = ['$today%'];

    if (adminId != null) {
      query += ' AND adminId = ?';
      args.add(adminId);
    }

    final result = await db.rawQuery(query, args);
    
    return {
      'totalAmount': result.first['totalAmount'] ?? 0.0,
      'totalCount': result.first['totalCount'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getSalesStatsForPeriod(String period, {String? adminId}) async {
    Database db = await database;
    String dateFormat;
    
    switch (period) {
      case 'Daily':
        dateFormat = '%Y-%m-%d';
        break;
      case 'Weekly':
        dateFormat = '%Y-%W'; // Week of year
        break;
      case 'Monthly':
        dateFormat = '%Y-%m';
        break;
      case 'Yearly':
        dateFormat = '%Y';
        break;
      default:
        dateFormat = '%Y-%m-%d';
    }

    String query = '''
      SELECT strftime(?, saleDate) as date, SUM(totalAmount) as amount, COUNT(*) as count 
      FROM sales 
    ''';
    List<Object?> args = [dateFormat];

    if (adminId != null) {
      query += ' WHERE adminId = ? ';
      args.add(adminId);
    }

    query += '''
      GROUP BY date 
      ORDER BY date DESC 
      LIMIT 12
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return maps;
  }

  // Users
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers({String? adminId}) async {
    Database db = await database;
    final String? whereClause = adminId != null ? 'adminId = ?' : null;
    final List<Object?>? whereArgs = adminId != null ? [adminId] : null;
    return await db.query('users', where: whereClause, whereArgs: whereArgs);
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    Database db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Settings
  Future<void> updateSetting(String key, String value, {String? adminId}) async {
    Database db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value, 'adminId': adminId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key, {String? adminId}) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ? AND adminId = ?',
      whereArgs: [key, adminId],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // Currency-specific methods
  Future<void> setCurrency(String currencyCode, {required String adminId}) async {
    await updateSetting('currency', currencyCode, adminId: adminId);
  }

  Future<String?> getCurrency({required String adminId}) async {
    return await getSetting('currency', adminId: adminId);
  }

  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('products');
    await db.delete('customers');
    await db.delete('sales');
    await db.delete('sale_items');
    await db.delete('expenses');
    await db.delete('suppliers');
    await db.delete('categories');
    // Note: We might want to keep users or settings, but "clean all database" usually refers to business data.
    // To be safe, let's keep the admin user.
    await _seedCategories(db, '1');
  }
}
