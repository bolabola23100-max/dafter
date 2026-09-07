import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/reports/model/report_summary.dart';

class ReportService {
  final AppDatabase _database;
  ReportService({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  Future<ReportSummary> getSummary({DateTime? from, DateTime? to}) async {
    final db = await _database.database;
    final sales = await _aggregate(db, DatabaseTables.sales, 'total', from, to);
    final purchases = await _aggregate(db, DatabaseTables.purchases, 'total', from, to);
    final expenses = await _aggregate(db, DatabaseTables.expenses, 'amount', from, to);
    final salesReturns = await _aggregate(db, DatabaseTables.saleReturns, 'total', from, to);
    final purchaseReturns = await _aggregate(db, DatabaseTables.purchaseReturns, 'total', from, to);

    final saleRows = await _dateRows(db, DatabaseTables.sales, from, to);
    var cogs = 0.0;
    for (final sale in saleRows) {
      final items = await db.query(DatabaseTables.saleItems, where: 'sale_id = ?', whereArgs: [sale['id']]);
      cogs += items.fold<double>(0, (sum, row) => sum +
          ((row['quantity'] as num?)?.toDouble() ?? 0) *
          ((row['cost_price'] as num?)?.toDouble() ?? 0));
    }

    final returnRows = await _dateRows(db, DatabaseTables.saleReturns, from, to);
    for (final returnRow in returnRows) {
      final items = await db.query(DatabaseTables.saleReturnItems, where: 'return_id = ?', whereArgs: [returnRow['id']]);
      for (final item in items) {
        final original = await db.query(DatabaseTables.saleItems,
            columns: ['cost_price'], where: 'id = ?', whereArgs: [item['sale_item_id']], limit: 1);
        if (original.isNotEmpty) {
          cogs -= ((item['quantity'] as num?)?.toDouble() ?? 0) *
              ((original.first['cost_price'] as num?)?.toDouble() ?? 0);
        }
      }
    }
    if (cogs < 0) cogs = 0;

    final productRows = await db.query(DatabaseTables.products);
    final stockValue = productRows.fold<double>(0, (sum, row) =>
        sum + ((row['quantity'] as num?)?.toDouble() ?? 0) *
        ((row['purchase_price'] as num?)?.toDouble() ?? 0));
    final suppliers = await db.rawQuery('SELECT COUNT(*) AS count FROM ${DatabaseTables.suppliers}');
    final customers = await db.rawQuery('SELECT COUNT(*) AS count FROM ${DatabaseTables.customers}');

    return ReportSummary(
      salesCount: sales.count, salesTotal: sales.total,
      purchasesCount: purchases.count, purchasesTotal: purchases.total,
      expensesCount: expenses.count, expensesTotal: expenses.total,
      salesReturnsCount: salesReturns.count, salesReturnsTotal: salesReturns.total,
      purchaseReturnsCount: purchaseReturns.count, purchaseReturnsTotal: purchaseReturns.total,
      productsCount: productRows.length, stockValue: stockValue,
      suppliersCount: (suppliers.first['count'] as num?)?.toInt() ?? 0,
      customersCount: (customers.first['count'] as num?)?.toInt() ?? 0,
      costOfGoodsSold: cogs,
    );
  }

  Future<List<Map<String, dynamic>>> _dateRows(dynamic db, String table, DateTime? from, DateTime? to) async {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) { where.add('date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { where.add('date < ?'); args.add(to.toIso8601String()); }
    return db.query(table, where: where.isEmpty ? null : where.join(' AND '), whereArgs: args.isEmpty ? null : args);
  }

  Future<_Aggregate> _aggregate(dynamic db, String table, String amountColumn, DateTime? from, DateTime? to) async {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) { where.add('date >= ?'); args.add(from.toIso8601String()); }
    if (to != null) { where.add('date < ?'); args.add(to.toIso8601String()); }
    final result = await db.rawQuery('SELECT COUNT(*) AS count, COALESCE(SUM($amountColumn), 0) AS total FROM $table${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}', args);
    final row = result.first;
    return _Aggregate(count: (row['count'] as num?)?.toInt() ?? 0, total: (row['total'] as num?)?.toDouble() ?? 0);
  }
}

class _Aggregate {
  final int count;
  final double total;
  const _Aggregate({required this.count, required this.total});
}
