import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_tables.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dafter.db');
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${DatabaseTables.suppliers} ADD COLUMN balance REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE ${DatabaseTables.suppliers} ADD COLUMN notes TEXT');
      await db.execute('UPDATE ${DatabaseTables.suppliers} SET balance = opening_balance WHERE balance = 0 AND opening_balance != 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE ${DatabaseTables.customers} ADD COLUMN balance REAL NOT NULL DEFAULT 0');
      await db.execute('UPDATE ${DatabaseTables.customers} SET balance = opening_balance WHERE balance = 0 AND opening_balance != 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE ${DatabaseTables.categories} (id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.products} (id TEXT PRIMARY KEY, name TEXT NOT NULL, barcode TEXT, category_id TEXT, purchase_price REAL NOT NULL DEFAULT 0, selling_price REAL NOT NULL DEFAULT 0, quantity INTEGER NOT NULL DEFAULT 0, min_quantity INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES ${DatabaseTables.categories}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.suppliers} (id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT, address TEXT, opening_balance REAL NOT NULL DEFAULT 0, balance REAL NOT NULL DEFAULT 0, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.customers} (id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT, address TEXT, opening_balance REAL NOT NULL DEFAULT 0, balance REAL NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.accounts} (id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL, opening_balance REAL NOT NULL DEFAULT 0, balance REAL NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.sales} (id TEXT PRIMARY KEY, customer_id TEXT, date TEXT NOT NULL, subtotal REAL NOT NULL DEFAULT 0, discount REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0, paid_amount REAL NOT NULL DEFAULT 0, notes TEXT, FOREIGN KEY (customer_id) REFERENCES ${DatabaseTables.customers}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.saleItems} (id TEXT PRIMARY KEY, sale_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, price REAL NOT NULL, discount REAL NOT NULL DEFAULT 0, subtotal REAL NOT NULL DEFAULT 0, FOREIGN KEY (sale_id) REFERENCES ${DatabaseTables.sales}(id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.purchases} (id TEXT PRIMARY KEY, supplier_id TEXT, date TEXT NOT NULL, subtotal REAL NOT NULL DEFAULT 0, discount REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0, paid_amount REAL NOT NULL DEFAULT 0, notes TEXT, FOREIGN KEY (supplier_id) REFERENCES ${DatabaseTables.suppliers}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.purchaseItems} (id TEXT PRIMARY KEY, purchase_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, price REAL NOT NULL, discount REAL NOT NULL DEFAULT 0, subtotal REAL NOT NULL DEFAULT 0, FOREIGN KEY (purchase_id) REFERENCES ${DatabaseTables.purchases}(id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.payments} (id TEXT PRIMARY KEY, type TEXT NOT NULL, person_type TEXT, person_id TEXT, account_id TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, notes TEXT, FOREIGN KEY (account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.expenses} (id TEXT PRIMARY KEY, account_id TEXT NOT NULL, category TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, notes TEXT, FOREIGN KEY (account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.stockMovements} (id TEXT PRIMARY KEY, product_id TEXT NOT NULL, type TEXT NOT NULL, quantity INTEGER NOT NULL, date TEXT NOT NULL, reference_id TEXT, notes TEXT, FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.accountTransactions} (id TEXT PRIMARY KEY, account_id TEXT NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL, is_debit INTEGER NOT NULL, date TEXT NOT NULL, reference_id TEXT, description TEXT, FOREIGN KEY (account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.transfers} (id TEXT PRIMARY KEY, from_account_id TEXT NOT NULL, to_account_id TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, notes TEXT, FOREIGN KEY (from_account_id) REFERENCES ${DatabaseTables.accounts}(id), FOREIGN KEY (to_account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_products_barcode ON ${DatabaseTables.products}(barcode)');
    await db.execute('CREATE INDEX idx_sale_items_sale_id ON ${DatabaseTables.saleItems}(sale_id)');
    await db.execute('CREATE INDEX idx_sale_items_product_id ON ${DatabaseTables.saleItems}(product_id)');
    await db.execute('CREATE INDEX idx_purchase_items_purchase_id ON ${DatabaseTables.purchaseItems}(purchase_id)');
    await db.execute('CREATE INDEX idx_purchase_items_product_id ON ${DatabaseTables.purchaseItems}(product_id)');
    await db.execute('CREATE INDEX idx_stock_movements_product_id ON ${DatabaseTables.stockMovements}(product_id)');
    await db.execute('CREATE INDEX idx_account_transactions_account_id ON ${DatabaseTables.accountTransactions}(account_id)');
  }
}
