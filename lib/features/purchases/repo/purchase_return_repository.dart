import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/purchase_return.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PurchaseReturnRepository {
  final AppDatabase _database;

  PurchaseReturnRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  Future<void> addReturnWithExecutor(
    DatabaseExecutor executor,
    PurchaseReturn purchaseReturn,
  ) async {
    await executor.insert(DatabaseTables.purchaseReturns, {
      'id': purchaseReturn.id,
      'purchase_id': purchaseReturn.purchaseId,
      'supplier_id': purchaseReturn.supplierId,
      'date': purchaseReturn.date.toIso8601String(),
      'total': purchaseReturn.total,
      'refunded_amount': purchaseReturn.refundedAmount,
      'notes': purchaseReturn.notes,
    });

    for (final item in purchaseReturn.items) {
      await executor.insert(DatabaseTables.purchaseReturnItems, {
        'id': item.id,
        'return_id': item.returnId,
        'purchase_item_id': item.purchaseItemId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'total': item.total,
      });
    }
  }

  Future<List<PurchaseReturn>> getReturns() async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseTables.purchaseReturns,
      orderBy: 'date DESC',
    );
    return Future.wait(rows.map((row) => _fromMap(db, row)));
  }

  Future<List<PurchaseReturn>> getReturnsByPurchase(String purchaseId) async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseTables.purchaseReturns,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
      orderBy: 'date DESC',
    );
    return Future.wait(rows.map((row) => _fromMap(db, row)));
  }

  Future<PurchaseReturn> _fromMap(
    DatabaseExecutor executor,
    Map<String, dynamic> map,
  ) async {
    final itemRows = await executor.query(
      DatabaseTables.purchaseReturnItems,
      where: 'return_id = ?',
      whereArgs: [map['id']],
    );

    return PurchaseReturn(
      id: map['id'] as String,
      purchaseId: map['purchase_id'] as String,
      supplierId: map['supplier_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      refundedAmount: (map['refunded_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      items: itemRows.map(
        (item) => PurchaseReturnItem(
          id: item['id'] as String,
          returnId: item['return_id'] as String,
          purchaseItemId: item['purchase_item_id'] as String,
          productId: item['product_id'] as String,
          quantity: item['quantity'] as int,
          price: (item['price'] as num).toDouble(),
        ),
      ).toList(),
    );
  }
}
