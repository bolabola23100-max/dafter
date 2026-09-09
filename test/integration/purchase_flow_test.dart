import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_item.dart';
import 'package:dafter/features/model/purchase_return.dart';
import 'package:dafter/features/purchases/service/purchase_return_service.dart';
import 'package:dafter/features/purchases/service/purchase_service.dart';
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
    await db.insert(DatabaseTables.suppliers, {
      'id': 'supplier-1',
      'name': 'Supplier',
      'opening_balance': 0,
      'balance': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert(DatabaseTables.products, {
      'id': 'product-1',
      'name': 'Product',
      'barcode': '2001',
      'purchase_price': 5,
      'selling_price': 9,
      'quantity': 3,
      'min_quantity': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() => database.close());

  Future<void> createPurchase({String id = 'purchase-1', String itemId = 'purchase-item-1'}) async {
    await PurchaseService(database: database).createPurchase(
      purchase: Purchase(
        id: id,
        supplierId: 'supplier-1',
        date: DateTime(2026, 9, 8, 11),
        paidAmount: 6,
        items: [
          PurchaseItem(
            id: itemId,
            purchaseId: id,
            productId: 'product-1',
            quantity: 2,
            price: 5,
          ),
        ],
      ),
      accountId: 'account-1',
    );
  }

  test('purchase flow updates stock, supplier, cash and ledgers', () async {
    final service = PurchaseService(database: database);
    final purchase = Purchase(
      id: 'purchase-1',
      supplierId: 'supplier-1',
      date: DateTime(2026, 9, 8, 11),
      paidAmount: 6,
      items: [
        PurchaseItem(
          id: 'purchase-item-1',
          purchaseId: 'purchase-1',
          productId: 'product-1',
          quantity: 2,
          price: 5,
        ),
      ],
    );

    await service.createPurchase(purchase: purchase, accountId: 'account-1');

    final product = (await db.query(
      DatabaseTables.products,
      where: 'id = ?',
      whereArgs: ['product-1'],
    )).single;
    expect(product['quantity'], 5);

    final supplier = (await db.query(
      DatabaseTables.suppliers,
      where: 'id = ?',
      whereArgs: ['supplier-1'],
    )).single;
    expect(supplier['balance'], 4);

    final account = (await db.query(
      DatabaseTables.accounts,
      where: 'id = ?',
      whereArgs: ['account-1'],
    )).single;
    expect(account['balance'], 94);

    final movements = await db.query(
      DatabaseTables.stockMovements,
      where: 'reference_id = ?',
      whereArgs: ['purchase-1'],
    );
    expect(movements, hasLength(1));
    expect(movements.single['quantity'], 2);

    final payments = await db.query(
      DatabaseTables.payments,
      where: 'account_id = ?',
      whereArgs: ['account-1'],
    );
    expect(payments, hasLength(1));
    expect(payments.single['amount'], 6);

    final transactions = await db.query(
      DatabaseTables.accountTransactions,
      where: 'reference_id = ?',
      whereArgs: ['purchase-1'],
    );
    expect(transactions, hasLength(1));
    expect(transactions.single['amount'], 6);
    expect(transactions.single['is_debit'], 1);
  });

  test('insufficient account balance is rejected without partial purchase mutation', () async {
    final service = PurchaseService(database: database);
    final purchase = Purchase(
      id: 'purchase-invalid',
      supplierId: 'supplier-1',
      date: DateTime(2026, 9, 8),
      paidAmount: 101,
      items: [
        PurchaseItem(
          id: 'purchase-item-invalid',
          purchaseId: 'purchase-invalid',
          productId: 'product-1',
          quantity: 1,
          price: 10,
        ),
      ],
    );

    await expectLater(
      service.createPurchase(purchase: purchase, accountId: 'account-1'),
      throwsA(isA<Exception>()),
    );

    expect(await db.query(DatabaseTables.purchases), isEmpty);
    expect(await db.query(DatabaseTables.purchaseItems), isEmpty);
    expect((await db.query(DatabaseTables.products)).single['quantity'], 3);
    expect((await db.query(DatabaseTables.accounts)).single['balance'], 100);
    expect(await db.query(DatabaseTables.payments), isEmpty);
  });

  test('purchase return updates stock, supplier credit and account correctly', () async {
    await createPurchase();

    await PurchaseReturnService(database: database).createReturn(
      purchaseId: 'purchase-1',
      items: [
        PurchaseReturnItem(
          id: 'purchase-return-item-1',
          returnId: 'ignored',
          purchaseItemId: 'purchase-item-1',
          productId: 'product-1',
          quantity: 1,
          price: 5,
        ),
      ],
      refundedAmount: 3,
      refundAccountId: 'account-1',
      date: DateTime(2026, 9, 8, 12),
    );

    expect((await db.query(DatabaseTables.products)).single['quantity'], 4);
    expect((await db.query(DatabaseTables.suppliers)).single['balance'], 2);
    expect((await db.query(DatabaseTables.accounts)).single['balance'], 97);

    final returns = await db.query(DatabaseTables.purchaseReturns);
    expect(returns, hasLength(1));
    expect(returns.single['total'], 5);
    expect(returns.single['refunded_amount'], 3);

    final movements = await db.query(
      DatabaseTables.stockMovements,
      where: 'reference_id = ?',
      whereArgs: [returns.single['id']],
    );
    expect(movements, hasLength(1));
    expect(movements.single['quantity'], -1);
  });

  test('duplicate purchase-item rows cannot exceed the purchased quantity', () async {
    await createPurchase();

    await expectLater(
      PurchaseReturnService(database: database).createReturn(
        purchaseId: 'purchase-1',
        items: [
          PurchaseReturnItem(
            id: 'purchase-return-item-2a',
            returnId: 'ignored',
            purchaseItemId: 'purchase-item-1',
            productId: 'product-1',
            quantity: 1,
            price: 5,
          ),
          PurchaseReturnItem(
            id: 'purchase-return-item-2b',
            returnId: 'ignored',
            purchaseItemId: 'purchase-item-1',
            productId: 'product-1',
            quantity: 2,
            price: 5,
          ),
        ],
      ),
      throwsA(isA<Exception>()),
    );

    expect(await db.query(DatabaseTables.purchaseReturns), isEmpty);
    expect((await db.query(DatabaseTables.products)).single['quantity'], 5);
    expect((await db.query(DatabaseTables.suppliers)).single['balance'], 4);
  });
}
