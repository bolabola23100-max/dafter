import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_item.dart';
import 'package:dafter/features/model/sale_return.dart';
import 'package:dafter/features/sales/service/sale_return_service.dart';
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
      'barcode': '3001',
      'purchase_price': 6,
      'selling_price': 10,
      'quantity': 10,
      'min_quantity': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() => database.close());

  test('return restores stock and only refunds the amount actually paid', () async {
    await SalesService(database: database).createSale(
      sale: Sale(
        id: 'sale-1',
        customerId: 'customer-1',
        date: DateTime(2026, 9, 8, 10),
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
      ),
      accountId: 'account-1',
    );

    await SaleReturnService(database: database).createReturn(
      saleReturn: SaleReturn(
        id: 'return-1',
        saleId: 'sale-1',
        customerId: 'customer-1',
        date: DateTime(2026, 9, 8, 12),
        refundedAmount: 5,
        items: [
          SaleReturnItem(
            id: 'return-item-1',
            returnId: 'return-1',
            saleItemId: 'sale-item-1',
            productId: 'product-1',
            quantity: 1,
            price: 10,
          ),
        ],
      ),
      accountId: 'account-1',
    );

    expect((await db.query(DatabaseTables.products)).single['quantity'], 9);
    expect((await db.query(DatabaseTables.accounts)).single['balance'], 100);
    expect((await db.query(DatabaseTables.customers)).single['balance'], 10);

    final movement = (await db.query(
      DatabaseTables.stockMovements,
      where: 'reference_id = ?',
      whereArgs: ['return-1'],
    )).single;
    expect(movement['quantity'], 1);

    final savedReturn = (await db.query(
      DatabaseTables.saleReturns,
      where: 'id = ?',
      whereArgs: ['return-1'],
    )).single;
    expect(savedReturn['refunded_amount'], 5);
    expect(savedReturn['total'], 10);
  });

  test('second refund cannot exceed the remaining paid amount', () async {
    await SalesService(database: database).createSale(
      sale: Sale(
        id: 'sale-2',
        customerId: 'customer-1',
        date: DateTime(2026, 9, 8),
        paidAmount: 5,
        items: [
          SaleItem(
            id: 'sale-item-2',
            saleId: 'sale-2',
            productId: 'product-1',
            quantity: 2,
            price: 10,
          ),
        ],
      ),
      accountId: 'account-1',
    );

    await SaleReturnService(database: database).createReturn(
      saleReturn: SaleReturn(
        id: 'return-2a',
        saleId: 'sale-2',
        customerId: 'customer-1',
        date: DateTime(2026, 9, 8, 12),
        refundedAmount: 5,
        items: [
          SaleReturnItem(
            id: 'return-item-2a',
            returnId: 'return-2a',
            saleItemId: 'sale-item-2',
            productId: 'product-1',
            quantity: 1,
            price: 10,
          ),
        ],
      ),
      accountId: 'account-1',
    );

    await expectLater(
      SaleReturnService(database: database).createReturn(
        saleReturn: SaleReturn(
          id: 'return-2b',
          saleId: 'sale-2',
          customerId: 'customer-1',
          date: DateTime(2026, 9, 8, 13),
          refundedAmount: 1,
          items: [
            SaleReturnItem(
              id: 'return-item-2b',
              returnId: 'return-2b',
              saleItemId: 'sale-item-2',
              productId: 'product-1',
              quantity: 1,
              price: 10,
            ),
          ],
        ),
        accountId: 'account-1',
      ),
      throwsA(isA<Exception>()),
    );

    expect((await db.query(DatabaseTables.saleReturns)).length, 1);
    expect((await db.query(DatabaseTables.products)).single['quantity'], 9);
  });
}
