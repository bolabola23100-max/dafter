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
      version: 6,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null) await database.close();
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
    if (oldVersion < 4) await _createPurchaseReturnTables(db);
    if (oldVersion < 5) {
      await _createSaleReturnTables(db);
      await _createSaleReturnIndexes(db);
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE ${DatabaseTables.saleItems} ADD COLUMN cost_price REAL NOT NULL DEFAULT 0');
      // Existing sales did not store historical cost. Snapshot the current
      // product purchase price so their profit stops changing in the future.
      await db.execute('''
        UPDATE ${DatabaseTables.saleItems}
        SET cost_price = COALESCE((
          SELECT purchase_price FROM ${DatabaseTables.products}
          WHERE ${DatabaseTables.products}.id = ${DatabaseTables.saleItems}.product_id
        ), 0)
        WHERE cost_price = 0
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE ${DatabaseTables.categories} (id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.products} (id TEXT PRIMARY KEY, name TEXT NOT NULL, barcode TEXT, category_id TEXT, purchase_price REAL NOT NULL DEFAULT 0, selling_price REAL NOT NULL DEFAULT 0, quantity INTEGER NOT NULL DEFAULT 0, min_quantity INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (category_id) REFERENCES ${DatabaseTables.categories}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.suppliers} (id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT, address TEXT, opening_balance REAL NOT NULL DEFAULT 0, balance REAL NOT NULL DEFAULT 0, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.customers} (id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT, address TEXT, opening_balance REAL NOT NULL DEFAULT 0, balance REAL NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.accounts} (id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL, opening_balance REAL NOT NULL DEFAULT 0, balance REAL NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.sales} (id TEXT PRIMARY KEY, customer_id TEXT, date TEXT NOT NULL, subtotal REAL NOT NULL DEFAULT 0, discount REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0, paid_amount REAL NOT NULL DEFAULT 0, notes TEXT, FOREIGN KEY (customer_id) REFERENCES ${DatabaseTables.customers}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.saleItems} (id TEXT PRIMARY KEY, sale_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, price REAL NOT NULL, discount REAL NOT NULL DEFAULT 0, subtotal REAL NOT NULL DEFAULT 0, cost_price REAL NOT NULL DEFAULT 0, FOREIGN KEY (sale_id) REFERENCES ${DatabaseTables.sales}(id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.purchases} (id TEXT PRIMARY KEY, supplier_id TEXT, date TEXT NOT NULL, subtotal REAL NOT NULL DEFAULT 0, discount REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0, paid_amount REAL NOT NULL DEFAULT 0, notes TEXT, FOREIGN KEY (supplier_id) REFERENCES ${DatabaseTables.suppliers}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE ${DatabaseTables.purchaseItems} (id TEXT PRIMARY KEY, purchase_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, price REAL NOT NULL, discount REAL NOT NULL DEFAULT 0, subtotal REAL NOT NULL DEFAULT 0, FOREIGN KEY (purchase_id) REFERENCES ${DatabaseTables.purchases}(id) ON DELETE CASCADE, FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.payments} (id TEXT PRIMARY KEY, type TEXT NOT NULL, person_type TEXT, person_id TEXT, account_id TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, notes TEXT, FOREIGN KEY (account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.expenses} (id TEXT PRIMARY KEY, account_id TEXT NOT NULL, category TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, notes TEXT, FOREIGN KEY (account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.stockMovements} (id TEXT PRIMARY KEY, product_id TEXT NOT NULL, type TEXT NOT NULL, quantity INTEGER NOT NULL, date TEXT NOT NULL, reference_id TEXT, notes TEXT, FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.accountTransactions} (id TEXT PRIMARY KEY, account_id TEXT NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL, is_debit INTEGER NOT NULL, date TEXT NOT NULL, reference_id TEXT, description TEXT, FOREIGN KEY (account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await db.execute('CREATE TABLE ${DatabaseTables.transfers} (id TEXT PRIMARY KEY, from_account_id TEXT NOT NULL, to_account_id TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, notes TEXT, FOREIGN KEY (from_account_id) REFERENCES ${DatabaseTables.accounts}(id), FOREIGN KEY (to_account_id) REFERENCES ${DatabaseTables.accounts}(id))');
    await _createPurchaseReturnTables(db);
    await _createSaleReturnTables(db);
    await _createIndexes(db);
    await _createSaleReturnIndexes(db);
  }

  Future<void> _createPurchaseReturnTables(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS ${DatabaseTables.purchaseReturns} (id TEXT PRIMARY KEY, purchase_id TEXT NOT NULL, supplier_id TEXT, date TEXT NOT NULL, total REAL NOT NULL DEFAULT 0, refunded_amount REAL NOT NULL DEFAULT 0, notes TEXT, FOREIGN KEY (purchase_id) REFERENCES ${DatabaseTables.purchases}(id), FOREIGN KEY (supplier_id) REFERENCES ${DatabaseTables.suppliers}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS ${DatabaseTables.purchaseReturnItems} (id TEXT PRIMARY KEY, return_id TEXT NOT NULL, purchase_item_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, price REAL NOT NULL, total REAL NOT NULL DEFAULT 0, FOREIGN KEY (return_id) REFERENCES ${DatabaseTables.purchaseReturns}(id) ON DELETE CASCADE, FOREIGN KEY (purchase_item_id) REFERENCES ${DatabaseTables.purchaseItems}(id), FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
  }

  Future<void> _createSaleReturnTables(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS ${DatabaseTables.saleReturns} (id TEXT PRIMARY KEY, sale_id TEXT NOT NULL, customer_id TEXT, date TEXT NOT NULL, total REAL NOT NULL DEFAULT 0, refunded_amount REAL NOT NULL DEFAULT 0, notes TEXT, FOREIGN KEY (sale_id) REFERENCES ${DatabaseTables.sales}(id), FOREIGN KEY (customer_id) REFERENCES ${DatabaseTables.customers}(id) ON DELETE SET NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS ${DatabaseTables.saleReturnItems} (id TEXT PRIMARY KEY, return_id TEXT NOT NULL, sale_item_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL, price REAL NOT NULL, total REAL NOT NULL DEFAULT 0, FOREIGN KEY (return_id) REFERENCES ${DatabaseTables.saleReturns}(id) ON DELETE CASCADE, FOREIGN KEY (sale_item_id) REFERENCES ${DatabaseTables.saleItems}(id), FOREIGN KEY (product_id) REFERENCES ${DatabaseTables.products}(id))');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON ${DatabaseTables.products}(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON ${DatabaseTables.saleItems}(sale_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON ${DatabaseTables.saleItems}(product_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON ${DatabaseTables.purchaseItems}(purchase_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON ${DatabaseTables.purchaseItems}(product_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON ${DatabaseTables.stockMovements}(product_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_account_transactions_account_id ON ${DatabaseTables.accountTransactions}(account_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_returns_purchase_id ON ${DatabaseTables.purchaseReturns}(purchase_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_return_items_return_id ON ${DatabaseTables.purchaseReturnItems}(return_id)');
  }

  Future<void> _createSaleReturnIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_returns_sale_id ON ${DatabaseTables.saleReturns}(sale_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_return_items_return_id ON ${DatabaseTables.saleReturnItems}(return_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_return_items_sale_item_id ON ${DatabaseTables.saleReturnItems}(sale_item_id)');
  }
}
