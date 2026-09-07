import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/reports/model/report_summary.dart';

class ReportService {
  final AppDatabase _database;

  ReportService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  Future<ReportSummary> getSummary({DateTime? from, DateTime? to}) async {
    final db = await _database.database;
    final sales = await _aggregate(db, DatabaseTables.sales, 'total', from, to);
    final purchases =
        await _aggregate(db, DatabaseTables.purchases, 'total', from, to);
    final expenses =
        await _aggregate(db, DatabaseTables.expenses, 'amount', from, to);
    final salesReturns = await _aggregate(
      db,
      DatabaseTables.saleReturns,
      'total',
      from,
      to,
    );
    final purchaseReturns = await _aggregate(
      db,
      DatabaseTables.purchaseReturns,
      'total',
      from,
      to,
    );

    final cogs = await _calculateCogs(db, from, to);

    final productRows = await db.query(DatabaseTables.products);
    final stockValue = productRows.fold<double>(
      0,
      (sum, row) =>
          sum +
          ((row['quantity'] as num?)?.toDouble() ?? 0) *
              ((row['purchase_price'] as num?)?.toDouble() ?? 0),
    );
    final suppliers = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseTables.suppliers}',
    );
    final customers = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseTables.customers}',
    );

    return ReportSummary(
      salesCount: sales.count,
      salesTotal: sales.total,
      purchasesCount: purchases.count,
      purchasesTotal: purchases.total,
      expensesCount: expenses.count,
      expensesTotal: expenses.total,
      salesReturnsCount: salesReturns.count,
      salesReturnsTotal: salesReturns.total,
      purchaseReturnsCount: purchaseReturns.count,
      purchaseReturnsTotal: purchaseReturns.total,
      productsCount: productRows.length,
      stockValue: stockValue,
      suppliersCount: (suppliers.first['count'] as num?)?.toInt() ?? 0,
      customersCount: (customers.first['count'] as num?)?.toInt() ?? 0,
      costOfGoodsSold: cogs,
    );
  }

  Future<double> _calculateCogs(
    dynamic db,
    DateTime? from,
    DateTime? to,
  ) async {
    final saleFilter = _dateFilter('s.date', from, to);
    final saleArgs = saleFilter.args;
    final saleResult = await db.rawQuery(
      'SELECT COALESCE(SUM(si.quantity * si.cost_price), 0) AS total '
      'FROM ${DatabaseTables.saleItems} si '
      'INNER JOIN ${DatabaseTables.sales} s ON s.id = si.sale_id'
      '${saleFilter.sql.isEmpty ? '' : ' WHERE ${saleFilter.sql}'}',
      saleArgs,
    );

    final returnFilter = _dateFilter('sr.date', from, to);
    final returnResult = await db.rawQuery(
      'SELECT COALESCE(SUM(sri.quantity * si.cost_price), 0) AS total '
      'FROM ${DatabaseTables.saleReturnItems} sri '
      'INNER JOIN ${DatabaseTables.saleReturns} sr ON sr.id = sri.return_id '
      'INNER JOIN ${DatabaseTables.saleItems} si ON si.id = sri.sale_item_id'
      '${returnFilter.sql.isEmpty ? '' : ' WHERE ${returnFilter.sql}'}',
      returnFilter.args,
    );

    final soldCost =
        (saleResult.first['total'] as num?)?.toDouble() ?? 0;
    final returnedCost =
        (returnResult.first['total'] as num?)?.toDouble() ?? 0;
    return (soldCost - returnedCost).clamp(0, double.infinity).toDouble();
  }

  _DateFilter _dateFilter(String column, DateTime? from, DateTime? to) {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('$column >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('$column < ?');
      args.add(to.toIso8601String());
    }
    return _DateFilter(
      sql: where.join(' AND '),
      args: args,
    );
  }

  Future<_Aggregate> _aggregate(
    dynamic db,
    String table,
    String amountColumn,
    DateTime? from,
    DateTime? to,
  ) async {
    final filter = _dateFilter('date', from, to);
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count, COALESCE(SUM($amountColumn), 0) AS total '
      'FROM $table${filter.sql.isEmpty ? '' : ' WHERE ${filter.sql}'}',
      filter.args,
    );
    final row = result.first;
    return _Aggregate(
      count: (row['count'] as num?)?.toInt() ?? 0,
      total: (row['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _DateFilter {
  final String sql;
  final List<Object?> args;

  const _DateFilter({required this.sql, required this.args});
}

class _Aggregate {
  final int count;
  final double total;

  const _Aggregate({required this.count, required this.total});
}
