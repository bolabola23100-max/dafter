import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_item.dart';
import 'package:dafter/features/reports/service/report_service.dart';
import 'package:dafter/features/sales/service/sales_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late dynamic db;

  setUp(() async {
    database = AppDatabase.forTesting();
    db = await database.database;

    await db.insert(DatabaseTables.accounts, {
      'id': 'account-1',
      'name': 'Cash',
      'type': 'cash',
      'opening_balance': 100,
      'balance': 100,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert(DatabaseTables.customers, {
      'id': 'customer-1',
      'name': 'Customer',
      'opening_balance': 0,
      'balance': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert(DatabaseTables.products, {
      'id': 'product-1',
      'name': 'Product',
      'barcode': '1001',
      'purchase_price': 6,
      'selling_price': 10,
      'quantity': 10,
      'min_quantity': 2,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() => database.close());

  test('sale flow updates stock, customer, cash, ledger and historical cost', () async {
    final service = SalesService(database: database);
    final date = DateTime(2026, 9, 8, 10);

    final sale = Sale(
      id: 'sale-1',
      customerId: 'customer-1',
      date: date,
      paidAmount: 5,
      items: [
        SaleItem(
          id: 'sale-item-1',
          saleId: 'sale-1',
          productId: 'product-1',
          quantity: 2,
          price: 10,
        ),
      ],
    );

    await service.createSale(sale: sale, accountId: 'account-1');

    final product = (await db.query(
      DatabaseTables.products,
      where: 'id = ?',
      whereArgs: ['product-1'],
    )).single;
    expect(product['quantity'], 8);

    final savedItem = (await db.query(
      DatabaseTables.saleItems,
      where: 'id = ?',
      whereArgs: ['sale-item-1'],
    )).single;
    expect(savedItem['cost_price'], 6);

    final customer = (await db.query(
      DatabaseTables.customers,
      where: 'id = ?',
      whereArgs: ['customer-1'],
    )).single;
    expect(customer['balance'], 15);

    final account = (await db.query(
      DatabaseTables.accounts,
      where: 'id = ?',
      whereArgs: ['account-1'],
    )).single;
    expect(account['balance'], 105);

    final movements = await db.query(
      DatabaseTables.stockMovements,
      where: 'reference_id = ?',
      whereArgs: ['sale-1'],
    );
    expect(movements, hasLength(1));
    expect(movements.single['quantity'], -2);

    final transactions = await db.query(
      DatabaseTables.accountTransactions,
      where: 'reference_id = ?',
      whereArgs: ['sale-1'],
    );
    expect(transactions, hasLength(1));
    expect(transactions.single['amount'], 5);

    final report = await ReportService(database: database).getSummary(
      from: DateTime(2026, 9, 8),
      to: DateTime(2026, 9, 9),
    );
    expect(report.salesCount, 1);
    expect(report.salesTotal, 20);
    expect(report.costOfGoodsSold, 12);
    expect(report.grossProfit, 8);
  });

  test('credit sale without customer is rejected before any database mutation', () async {
    final service = SalesService(database: database);
    final sale = Sale(
      id: 'sale-invalid',
      date: DateTime(2026, 9, 8),
      items: [
        SaleItem(
          id: 'sale-item-invalid',
          saleId: 'sale-invalid',
          productId: 'product-1',
          quantity: 1,
          price: 10,
        ),
      ],
    );

    await expectLater(
      service.createSale(sale: sale),
      throwsA(isA<Exception>()),
    );

    expect(await db.query(DatabaseTables.sales), isEmpty);
    expect(await db.query(DatabaseTables.saleItems), isEmpty);

    final product = (await db.query(
      DatabaseTables.products,
      where: 'id = ?',
      whereArgs: ['product-1'],
    )).single;
    expect(product['quantity'], 10);
  });
}
