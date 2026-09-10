import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ProductRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    repository = ProductRepository(database: database);
    final db = await database.database;
    await db.insert(DatabaseTables.products, {
      'id': 'empty-product',
      'name': 'Empty Product',
      'purchase_price': 5,
      'selling_price': 8,
      'quantity': 0,
      'min_quantity': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert(DatabaseTables.products, {
      'id': 'stock-product',
      'name': 'Stock Product',
      'purchase_price': 5,
      'selling_price': 8,
      'quantity': 2,
      'min_quantity': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() => database.close());

  test('zero-stock product with no history can be deleted', () async {
    await repository.deleteProduct('empty-product');
    final db = await database.database;
    expect(await db.query(DatabaseTables.products, where: 'id = ?', whereArgs: ['empty-product']), isEmpty);
  });

  test('product with current stock cannot be deleted', () async {
    await expectLater(repository.deleteProduct('stock-product'), throwsA(isA<Exception>()));
    final db = await database.database;
    expect(await db.query(DatabaseTables.products, where: 'id = ?', whereArgs: ['stock-product']), hasLength(1));
  });

  test('zero-stock product with stock history cannot be physically deleted', () async {
    final db = await database.database;
    await db.update(DatabaseTables.products, {'quantity': 0}, where: 'id = ?', whereArgs: ['stock-product']);
    await db.insert(DatabaseTables.stockMovements, {
      'id': 'movement-1',
      'product_id': 'stock-product',
      'type': 'adjustment',
      'quantity': 2,
      'date': DateTime.now().toIso8601String(),
      'reference_id': 'stock-product',
      'notes': 'test',
    });

    await expectLater(repository.deleteProduct('stock-product'), throwsA(isA<Exception>()));
    expect(await db.query(DatabaseTables.products, where: 'id = ?', whereArgs: ['stock-product']), hasLength(1));
  });
}
