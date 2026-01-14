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
      version: 7, // Incremented version to 7 for Purchase Price
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
      await _seedCategories(db);
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
        await db.insert('users', {
          'name': 'Admin',
          'role': 'Admin',
          'lastActive': DateTime.now().toString(),
          'email': 'admin@pos.com',
          'password': 'adminpassword',
          'permissions': '["all"]'
        });
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
        purchasePrice REAL DEFAULT 0.0
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
        is_synced INTEGER DEFAULT 0
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
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT NOT NULL,
        lastOrder TEXT NOT NULL,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        supabase_id TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    
    // Initialize last backup date
    await db.insert('settings', {'key': 'last_backup_date', 'value': ''});

    // Seed default categories
    await _seedCategories(db);

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
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Seed initial users
    await db.insert('users', {
      'name': 'Admin', 
      'role': 'Admin', 
      'lastActive': 'Oct 18, 2025',
      'email': 'admin@pos.com',
      'password': 'adminpassword',
      'permissions': '["all"]'
    });
    await db.insert('users', {
      'name': 'Jane Smith', 
      'role': 'Cashier', 
      'lastActive': 'Oct 17, 2025',
      'email': 'jane@pos.com',
      'password': 'password123',
      'permissions': '["sales", "customers", "reports"]'
    });
  }

  Future<void> _seedCategories(Database db) async {
    final List<String> defaultCategories = [
      'Electronics',
      'Clothing',
      'Accessories',
      'Groceries',
      'Home & Kitchen',
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', {'name': cat}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // Generic CRUD operations can be added here or specialized methods
  
  // Products
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
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

  Future<List<Product>> getFavoriteProducts() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'is_favorite = 1',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Customers
  Future<int> insertCustomer(CustomerModel customer) async {
    Database db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<CustomerModel>> getCustomers() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
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

  Future<List<Map<String, dynamic>>> getExpenses() async {
    Database db = await database;
    return await db.query('expenses');
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

  Future<List<Map<String, dynamic>>> getSuppliers() async {
    Database db = await database;
    return await db.query('suppliers');
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
  Future<int> insertCategory(String name) async {
    Database db = await database;
    return await db.insert('categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCategories() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
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
        });
        
        // Update product quantity
        await txn.execute(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      return saleId;
    });
  }

  Future<Map<String, dynamic>> getSalesSummary() async {
    Database db = await database;
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as totalAmount, COUNT(*) as totalCount FROM sales WHERE saleDate LIKE ?',
      ['$today%'],
    );
    
    return {
      'totalAmount': result.first['totalAmount'] ?? 0.0,
      'totalCount': result.first['totalCount'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getSalesStatsForPeriod(String period) async {
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

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT strftime(?, saleDate) as date, SUM(totalAmount) as amount, COUNT(*) as count 
      FROM sales 
      GROUP BY date 
      ORDER BY date DESC 
      LIMIT 12
    ''', [dateFormat]);

    return maps;
  }

  // Users
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users');
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
  Future<void> updateSetting(String key, String value) async {
    Database db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
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
    await _seedCategories(db);
  }
}
