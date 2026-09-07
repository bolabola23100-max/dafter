import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SalesRepository {
  final AppDatabase _database;

  SalesRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  Future<void> addSale(Sale sale) async {
    final db = await _database.database;
    await addSaleWithExecutor(db, sale);
  }

  Future<void> addSaleWithExecutor(DatabaseExecutor executor, Sale sale) async {
    await executor.insert(DatabaseTables.sales, {
      'id': sale.id,
      'customer_id': sale.customerId,
      'date': sale.date.toIso8601String(),
      'subtotal': sale.subtotal,
      'discount': sale.discount,
      'total': sale.total,
      'paid_amount': sale.paidAmount,
      'notes': sale.notes,
    });

    for (final item in sale.items) {
      await executor.insert(DatabaseTables.saleItems, {
        'id': item.id,
        'sale_id': item.saleId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'discount': item.discount,
        'subtotal': item.subtotal,
        'cost_price': item.costPrice,
      });
    }
  }

  Future<List<Sale>> getSales() async {
    final db = await _database.database;
    final rows = await db.query(DatabaseTables.sales, orderBy: 'date DESC');
    return Future.wait(rows.map((row) => _fromMap(db, row)));
  }

  Future<List<Sale>> getSalesByCustomer(String customerId) async {
    final db = await _database.database;
    final rows = await db.query(DatabaseTables.sales, where: 'customer_id = ?', whereArgs: [customerId], orderBy: 'date DESC');
    return Future.wait(rows.map((row) => _fromMap(db, row)));
  }

  Future<Sale?> getSaleById(String id) async {
    final db = await _database.database;
    return getSaleByIdWithExecutor(db, id);
  }

  Future<Sale?> getSaleByIdWithExecutor(DatabaseExecutor executor, String id) async {
    final rows = await executor.query(DatabaseTables.sales, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _fromMap(executor, rows.first);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final db = await _database.database;
    return getSaleItemsWithExecutor(db, saleId);
  }

  Future<List<SaleItem>> getSaleItemsWithExecutor(DatabaseExecutor executor, String saleId) async {
    final rows = await executor.query(DatabaseTables.saleItems, where: 'sale_id = ?', whereArgs: [saleId]);
    return rows.map(_itemFromMap).toList();
  }

  Future<Sale> _fromMap(DatabaseExecutor executor, Map<String, dynamic> row) async {
    final items = await getSaleItemsWithExecutor(executor, row['id'] as String);
    final paid = (row['paid_amount'] as num).toDouble();
    final total = (row['total'] as num).toDouble();
    final status = paid >= total && total > 0
        ? PaymentStatus.paid
        : paid > 0
            ? PaymentStatus.partial
            : PaymentStatus.unpaid;

    return Sale(
      id: row['id'] as String,
      customerId: row['customer_id'] as String?,
      date: DateTime.parse(row['date'] as String),
      items: items,
      discount: (row['discount'] as num).toDouble(),
      paidAmount: paid,
      paymentStatus: status,
      notes: row['notes'] as String?,
    );
  }

  SaleItem _itemFromMap(Map<String, dynamic> row) => SaleItem(
        id: row['id'] as String,
        saleId: row['sale_id'] as String,
        productId: row['product_id'] as String,
        quantity: row['quantity'] as int,
        price: (row['price'] as num).toDouble(),
        discount: (row['discount'] as num).toDouble(),
        costPrice: (row['cost_price'] as num?)?.toDouble() ?? 0,
      );
}
