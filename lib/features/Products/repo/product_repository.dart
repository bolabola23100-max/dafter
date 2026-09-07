import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductRepository {
  final AppDatabase _database;
  ProductRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  Future<void> addProduct(Product product) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(DatabaseTables.products, {
        'id': product.id, 'name': product.name, 'barcode': product.barcode, 'category_id': product.categoryId,
        'purchase_price': product.purchasePrice, 'selling_price': product.sellingPrice, 'quantity': product.quantity,
        'min_quantity': product.minQuantity, 'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(),
      });
      if (product.quantity != 0) {
        await txn.insert(DatabaseTables.stockMovements, {
          'id': _generateId(), 'product_id': product.id, 'type': StockMovementType.adjustment.name,
          'quantity': product.quantity, 'date': DateTime.now().toIso8601String(), 'reference_id': product.id, 'notes': 'رصيد افتتاحي للمنتج',
        });
      }
    });
  }

  Future<List<Product>> getProducts() async {
    final db = await _database.database;
    return (await db.query(DatabaseTables.products, orderBy: 'name ASC')).map(_fromMap).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await _database.database;
    return getProductByIdWithExecutor(db, id);
  }

  Future<Product?> getProductByIdWithExecutor(DatabaseExecutor executor, String id) async {
    final result = await executor.query(DatabaseTables.products, where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isEmpty ? null : _fromMap(result.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _database.database;
    final result = await db.query(DatabaseTables.products, where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    return result.isEmpty ? null : _fromMap(result.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _database.database;
    final result = await db.query(DatabaseTables.products, where: 'name LIKE ? OR barcode LIKE ?', whereArgs: ['%$query%', '%$query%'], orderBy: 'name ASC');
    return result.map(_fromMap).toList();
  }

  Future<void> updateProduct(Product product) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final existing = await getProductByIdWithExecutor(txn, product.id);
      if (existing == null) throw Exception('المنتج غير موجود');
      if (product.quantity < 0) throw Exception('كمية المنتج مينفعش تكون سالبة');
      await txn.update(DatabaseTables.products, {
        'name': product.name, 'barcode': product.barcode, 'category_id': product.categoryId,
        'purchase_price': product.purchasePrice, 'selling_price': product.sellingPrice,
        'quantity': product.quantity, 'min_quantity': product.minQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = ?', whereArgs: [product.id]);

      final delta = product.quantity - existing.quantity;
      if (delta != 0) {
        await txn.insert(DatabaseTables.stockMovements, {
          'id': _generateId(), 'product_id': product.id, 'type': StockMovementType.adjustment.name,
          'quantity': delta, 'date': DateTime.now().toIso8601String(), 'reference_id': product.id,
          'notes': 'تعديل يدوي للمخزون',
        });
      }
    });
  }

  Future<void> deleteProduct(String id) async {
    final db = await _database.database;
    final movements = await db.query(DatabaseTables.stockMovements, columns: ['id'], where: 'product_id = ?', whereArgs: [id], limit: 1);
    if (movements.isNotEmpty) throw Exception('مينفعش تحذف منتج عليه حركات مخزون');
    await db.delete(DatabaseTables.products, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    final db = await _database.database;
    await updateStockWithExecutor(db, productId, newQuantity);
  }

  Future<void> updateStockWithExecutor(DatabaseExecutor executor, String productId, int newQuantity) async {
    if (newQuantity < 0) throw Exception('المخزون مينفعش يكون بالسالب');
    await executor.update(DatabaseTables.products, {'quantity': newQuantity, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [productId]);
  }

  Product _fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as String, name: map['name'] as String, barcode: map['barcode'] as String?, categoryId: map['category_id'] as String?,
    purchasePrice: (map['purchase_price'] as num).toDouble(), sellingPrice: (map['selling_price'] as num).toDouble(),
    quantity: map['quantity'] as int, minQuantity: map['min_quantity'] as int,
  );

  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().microsecond}';
}
