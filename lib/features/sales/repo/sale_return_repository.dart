import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/sale_return.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SaleReturnRepository {
  final AppDatabase _database;

  SaleReturnRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  Future<void> addReturnWithExecutor(
    DatabaseExecutor executor,
    SaleReturn saleReturn,
  ) async {
    await executor.insert(DatabaseTables.saleReturns, {
      'id': saleReturn.id,
      'sale_id': saleReturn.saleId,
      'customer_id': saleReturn.customerId,
      'date': saleReturn.date.toIso8601String(),
      'total': saleReturn.total,
      'refunded_amount': saleReturn.refundedAmount,
      'notes': saleReturn.notes,
    });

    for (final item in saleReturn.items) {
      await executor.insert(DatabaseTables.saleReturnItems, {
        'id': item.id,
        'return_id': item.returnId,
        'sale_item_id': item.saleItemId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'total': item.total,
      });
    }
  }

  Future<List<SaleReturn>> getReturns() async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseTables.saleReturns,
      orderBy: 'date DESC',
    );
    return Future.wait(rows.map((row) => _fromMap(db, row)));
  }

  Future<List<SaleReturn>> getReturnsBySale(String saleId) async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseTables.saleReturns,
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'date DESC',
    );
    return Future.wait(rows.map((row) => _fromMap(db, row)));
  }

  Future<SaleReturn> _fromMap(
    DatabaseExecutor executor,
    Map<String, dynamic> map,
  ) async {
    final itemRows = await executor.query(
      DatabaseTables.saleReturnItems,
      where: 'return_id = ?',
      whereArgs: [map['id']],
    );

    return SaleReturn(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
      customerId: map['customer_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      refundedAmount: (map['refunded_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      items: itemRows
          .map(
            (item) => SaleReturnItem(
              id: item['id'] as String,
              returnId: item['return_id'] as String,
              saleItemId: item['sale_item_id'] as String,
              productId: item['product_id'] as String,
              quantity: item['quantity'] as int,
              price: (item['price'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
