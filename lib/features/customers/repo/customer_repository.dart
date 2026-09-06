import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/customers/model/customer.dart';

class CustomerRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<void> addCustomer(Customer customer) async {
    final db = await _database.database;
    await db.insert(DatabaseTables.customers, _toMap(customer));
  }

  Future<List<Customer>> getCustomers() async {
    final db = await _database.database;
    final rows = await db.query(DatabaseTables.customers, orderBy: 'name ASC');
    return rows.map(_fromMap).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseTables.customers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  Future<Customer?> getCustomerByIdWithExecutor(
    DatabaseExecutor executor,
    String id,
  ) async {
    final rows = await executor.query(
      DatabaseTables.customers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await _database.database;
    final value = '%${query.trim()}%';
    final rows = await db.query(
      DatabaseTables.customers,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [value, value],
      orderBy: 'name ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _database.database;
    await db.update(
      DatabaseTables.customers,
      _toMap(customer),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> updateBalance(String customerId, double newBalance) async {
    final db = await _database.database;
    await db.update(
      DatabaseTables.customers,
      {'balance': newBalance, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<void> updateBalanceWithExecutor(
    DatabaseExecutor executor,
    String customerId,
    double newBalance,
  ) async {
    await executor.update(
      DatabaseTables.customers,
      {'balance': newBalance, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _database.database;
    await db.delete(
      DatabaseTables.customers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toMap(Customer customer) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': customer.id,
      'name': customer.name.trim(),
      'phone': customer.phone?.trim().isEmpty == true ? null : customer.phone?.trim(),
      'address': customer.address?.trim().isEmpty == true ? null : customer.address?.trim(),
      'opening_balance': customer.openingBalance,
      'balance': customer.balance,
      'created_at': now,
      'updated_at': now,
    };
  }

  Customer _fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
