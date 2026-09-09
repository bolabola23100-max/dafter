import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PurchaseRepository {
  final AppDatabase _database;

  PurchaseRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  Future<void> addPurchase(Purchase purchase) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await addPurchaseWithExecutor(txn, purchase);
    });
  }

  Future<void> addPurchaseWithExecutor(
    DatabaseExecutor executor,
    Purchase purchase,
  ) async {
    await executor.insert(DatabaseTables.purchases, {
      'id': purchase.id,
      'supplier_id': purchase.supplierId,
      'date': purchase.date.toIso8601String(),
      'subtotal': purchase.subtotal,
      'discount': purchase.discount,
      'total': purchase.total,
      'paid_amount': purchase.paidAmount,
      'notes': purchase.notes,
    });

    for (final item in purchase.items) {
      await executor.insert(DatabaseTables.purchaseItems, {
        'id': item.id,
        'purchase_id': item.purchaseId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'discount': item.discount,
        'subtotal': item.subtotal,
      });
    }
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await _database.database;
    final purchasesResult = await db.query(
      DatabaseTables.purchases,
      orderBy: 'date DESC',
    );

    final purchases = <Purchase>[];
    for (final purchaseMap in purchasesResult) {
      purchases.add(await _fromMap(db, purchaseMap));
    }
    return purchases;
  }

  Future<List<Purchase>> getPurchasesBySupplier(String supplierId) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.purchases,
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'date DESC',
    );

    final purchases = <Purchase>[];
    for (final purchaseMap in result) {
      purchases.add(await _fromMap(db, purchaseMap));
    }
    return purchases;
  }

  Future<Purchase?> getPurchaseById(String id) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.purchases,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return _fromMap(db, result.first);
  }

  Future<List<PurchaseItem>> getPurchaseItems(String purchaseId) async {
    final db = await _database.database;
    return getPurchaseItemsWithExecutor(db, purchaseId);
  }

  Future<List<PurchaseItem>> getPurchaseItemsWithExecutor(
    DatabaseExecutor executor,
    String purchaseId,
  ) async {
    final result = await executor.query(
      DatabaseTables.purchaseItems,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return result.map(_itemFromMap).toList();
  }

  Future<List<Purchase>> searchPurchases(String query) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.purchases,
      where: 'id LIKE ? OR supplier_id LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    final purchases = <Purchase>[];
    for (final purchaseMap in result) {
      purchases.add(await _fromMap(db, purchaseMap));
    }
    return purchases;
  }

  Future<Purchase> _fromMap(
    DatabaseExecutor executor,
    Map<String, dynamic> map,
  ) async {
    final itemsResult = await executor.query(
      DatabaseTables.purchaseItems,
      where: 'purchase_id = ?',
      whereArgs: [map['id']],
    );

    return Purchase(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      items: itemsResult.map(_itemFromMap).toList(),
      discount: (map['discount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  PurchaseItem _itemFromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as String,
      purchaseId: map['purchase_id'] as String,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
    );
  }
}
