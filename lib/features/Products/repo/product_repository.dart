import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductRepository {
  final AppDatabase _database;

  ProductRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  Future<void> addProduct(Product product) async {
    final db = await _database.database;

    await db.insert(DatabaseTables.products, {
      'id': product.id,
      'name': product.name,
      'barcode': product.barcode,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'selling_price': product.sellingPrice,
      'quantity': product.quantity,
      'min_quantity': product.minQuantity,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Product>> getProducts() async {
    final db = await _database.database;

    final result = await db.query(DatabaseTables.products, orderBy: 'name ASC');

    return result.map(_fromMap).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await _database.database;

    return getProductByIdWithExecutor(db, id);
  }

  Future<Product?> getProductByIdWithExecutor(
    DatabaseExecutor executor,
    String id,
  ) async {
    final result = await executor.query(
      DatabaseTables.products,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.products,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.products,
      where: '''
        name LIKE ?
        OR barcode LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return result.map(_fromMap).toList();
  }

  Future<void> updateProduct(Product product) async {
    final db = await _database.database;

    await db.update(
      DatabaseTables.products,
      {
        'name': product.name,
        'barcode': product.barcode,
        'category_id': product.categoryId,
        'purchase_price': product.purchasePrice,
        'selling_price': product.sellingPrice,
        'quantity': product.quantity,
        'min_quantity': product.minQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _database.database;

    await db.delete(DatabaseTables.products, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    final db = await _database.database;

    await updateStockWithExecutor(db, productId, newQuantity);
  }

  Future<void> updateStockWithExecutor(
    DatabaseExecutor executor,
    String productId,
    int newQuantity,
  ) async {
    await executor.update(
      DatabaseTables.products,
      {'quantity': newQuantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Product _fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      categoryId: map['category_id'] as String?,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      minQuantity: map['min_quantity'] as int,
    );
  }
}
