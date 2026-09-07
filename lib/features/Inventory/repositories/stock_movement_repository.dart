import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/stock_movement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StockMovementRepository {
  final AppDatabase _database;

  StockMovementRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  Future<void> addMovement(StockMovement movement) async {
    final db = await _database.database;
    await addMovementWithExecutor(db, movement);
  }

  Future<void> addMovementWithExecutor(
    DatabaseExecutor executor,
    StockMovement movement,
  ) async {
    if (movement.quantity == 0) {
      throw Exception('حركة المخزون لازم يكون لها تأثير فعلي');
    }
    await executor.insert(DatabaseTables.stockMovements, {
      'id': movement.id,
      'product_id': movement.productId,
      'type': movement.type.name,
      'quantity': movement.quantity,
      'date': movement.date.toIso8601String(),
      'reference_id': movement.referenceId,
      'notes': movement.notes,
    });
  }

  Future<List<StockMovement>> getProductMovements(String productId) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.stockMovements,
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return result.map(_fromMap).toList();
  }

  Future<List<StockMovement>> getAllMovements() async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.stockMovements,
      orderBy: 'date DESC',
    );
    return result.map(_fromMap).toList();
  }

  Future<StockMovement?> getMovementById(String id) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.stockMovements,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isEmpty ? null : _fromMap(result.first);
  }

  StockMovement _fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      type: StockMovementType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => StockMovementType.adjustment,
      ),
      quantity: map['quantity'] as int,
      date: DateTime.parse(map['date'] as String),
      referenceId: map['reference_id'] as String?,
      notes: map['notes'] as String?,
    );
  }
}