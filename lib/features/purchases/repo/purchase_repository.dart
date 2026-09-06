import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PurchaseRepository {
  final AppDatabase _database;

  PurchaseRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  // =========================
  // Add Purchase
  // =========================

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
    final now = DateTime.now().toIso8601String();

    // Save purchase
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

    // Save purchase items
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

  // =========================
  // Get Purchases
  // =========================

  Future<List<Purchase>> getPurchases() async {
    final db = await _database.database;

    final purchasesResult = await db.query(
      DatabaseTables.purchases,
      orderBy: 'date DESC',
    );

    final purchases = <Purchase>[];

    for (final purchaseMap in purchasesResult) {
      final purchase = await _fromMap(db, purchaseMap);
      purchases.add(purchase);
    }

    return purchases;
  }

  // =========================
  // Get Purchase By ID
  // =========================

  Future<Purchase?> getPurchaseById(String id) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.purchases,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(db, result.first);
  }

  // =========================
  // Get Purchase Items
  // =========================

  Future<List<PurchaseItem>> getPurchaseItems(String purchaseId) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.purchaseItems,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );

    return result.map(_itemFromMap).toList();
  }

  // =========================
  // Update Purchase
  // =========================

  Future<void> updatePurchase(Purchase purchase) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      await txn.update(
        DatabaseTables.purchases,
        {
          'supplier_id': purchase.supplierId,
          'date': purchase.date.toIso8601String(),
          'subtotal': purchase.subtotal,
          'discount': purchase.discount,
          'total': purchase.total,
          'paid_amount': purchase.paidAmount,
          'notes': purchase.notes,
        },
        where: 'id = ?',
        whereArgs: [purchase.id],
      );

      // Delete old items
      await txn.delete(
        DatabaseTables.purchaseItems,
        where: 'purchase_id = ?',
        whereArgs: [purchase.id],
      );

      // Insert new items
      for (final item in purchase.items) {
        await txn.insert(DatabaseTables.purchaseItems, {
          'id': item.id,
          'purchase_id': item.purchaseId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
          'discount': item.discount,
          'subtotal': item.subtotal,
        });
      }
    });
  }

  // =========================
  // Delete Purchase
  // =========================

  Future<void> deletePurchase(String id) async {
    final db = await _database.database;

    await db.delete(DatabaseTables.purchases, where: 'id = ?', whereArgs: [id]);
  }

  // =========================
  // Search Purchases
  // =========================

  Future<List<Purchase>> searchPurchases(String query) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.purchases,
      where: '''
        id LIKE ?
        OR supplier_id LIKE ?
        OR notes LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    final purchases = <Purchase>[];

    for (final purchaseMap in result) {
      purchases.add(await _fromMap(db, purchaseMap));
    }

    return purchases;
  }

  // =========================
  // Private: Purchase Mapper
  // =========================

  Future<Purchase> _fromMap(
    DatabaseExecutor executor,
    Map<String, dynamic> map,
  ) async {
    final itemsResult = await executor.query(
      DatabaseTables.purchaseItems,
      where: 'purchase_id = ?',
      whereArgs: [map['id']],
    );

    final items = itemsResult.map(_itemFromMap).toList();

    return Purchase(
      id: map['id'] as String,
      supplierId: map['supplier_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      items: items,
      discount: (map['discount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  // =========================
  // Private: Item Mapper
  // =========================

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
