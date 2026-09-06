import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SupplierRepository {
  final AppDatabase _database;

  SupplierRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  // =========================
  // Add Supplier
  // =========================

  Future<void> addSupplier(Supplier supplier) async {
    final db = await _database.database;

    final now = DateTime.now().toIso8601String();

    await db.insert(DatabaseTables.suppliers, {
      'id': supplier.id,
      'name': supplier.name,
      'phone': supplier.phone,
      'address': supplier.address,
      'opening_balance': supplier.openingBalance,
      'balance': supplier.balance,
      'created_at': now,
      'updated_at': now,
    });
  }

  // =========================
  // Get Suppliers
  // =========================

  Future<List<Supplier>> getSuppliers() async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.suppliers,
      orderBy: 'name ASC',
    );

    return result.map(_fromMap).toList();
  }

  // =========================
  // Get Supplier By ID
  // =========================

  Future<Supplier?> getSupplierById(String id) async {
    final db = await _database.database;

    return getSupplierByIdWithExecutor(db, id);
  }

  Future<Supplier?> getSupplierByIdWithExecutor(
    DatabaseExecutor executor,
    String id,
  ) async {
    final result = await executor.query(
      DatabaseTables.suppliers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _fromMap(result.first);
  }

  // =========================
  // Search Suppliers
  // =========================

  Future<List<Supplier>> searchSuppliers(String query) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.suppliers,
      where: '''
        name LIKE ?
        OR phone LIKE ?
      ''',
      whereArgs: [
        '%$query%',
        '%$query%',
      ],
      orderBy: 'name ASC',
    );

    return result.map(_fromMap).toList();
  }

  // =========================
  // Update Supplier
  // =========================

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await _database.database;

    await db.update(
      DatabaseTables.suppliers,
      {
        'name': supplier.name,
        'phone': supplier.phone,
        'address': supplier.address,
        'opening_balance': supplier.openingBalance,
        'balance': supplier.balance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  // =========================
  // Update Balance
  // =========================

  Future<void> updateBalance(
    String supplierId,
    double newBalance,
  ) async {
    final db = await _database.database;

    await updateBalanceWithExecutor(
      db,
      supplierId,
      newBalance,
    );
  }

  Future<void> updateBalanceWithExecutor(
    DatabaseExecutor executor,
    String supplierId,
    double newBalance,
  ) async {
    await executor.update(
      DatabaseTables.suppliers,
      {
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  // =========================
  // Update Opening Balance
  // =========================

  Future<void> updateOpeningBalance(
    String supplierId,
    double amount,
  ) async {
    final db = await _database.database;

    await db.update(
      DatabaseTables.suppliers,
      {
        'opening_balance': amount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [supplierId],
    );
  }

  // =========================
  // Delete Supplier
  // =========================

  Future<void> deleteSupplier(String id) async {
    final db = await _database.database;

    await db.delete(
      DatabaseTables.suppliers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // Mapper
  // =========================

  Supplier _fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      openingBalance: (map['opening_balance'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}