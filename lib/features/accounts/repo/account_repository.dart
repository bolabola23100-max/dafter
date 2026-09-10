import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/account.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AccountRepository {
  final AppDatabase _database;

  AccountRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  void _validateAccount(Account account) {
    if (account.id.trim().isEmpty) throw ArgumentError('معرف الحساب غير صالح');
    if (account.name.trim().isEmpty) throw ArgumentError('اسم الحساب مطلوب');
    if (!account.openingBalance.isFinite || !account.balance.isFinite) {
      throw ArgumentError('رصيد الحساب غير صالح');
    }
  }

  Future<void> addAccount(Account account) async {
    _validateAccount(account);

    final db = await _database.database;
    await db.insert(DatabaseTables.accounts, {
      'id': account.id,
      'name': account.name.trim(),
      'type': account.type.name,
      'opening_balance': account.openingBalance,
      'balance': account.balance,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Account>> getAccounts() async {
    final db = await _database.database;
    final result = await db.query(DatabaseTables.accounts, orderBy: 'name ASC');
    return result.map(_fromMap).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.accounts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return _fromMap(result.first);
  }

  Future<Account?> getAccountByIdWithExecutor(
    DatabaseExecutor executor,
    String id,
  ) async {
    final result = await executor.query(
      DatabaseTables.accounts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return _fromMap(result.first);
  }

  Future<void> updateBalance(String accountId, double newBalance) async {
    final db = await _database.database;
    await updateBalanceWithExecutor(db, accountId, newBalance);
  }

  Future<void> updateBalanceWithExecutor(
    DatabaseExecutor executor,
    String accountId,
    double newBalance,
  ) async {
    if (!newBalance.isFinite) {
      throw ArgumentError.value(newBalance, 'newBalance', 'رصيد الحساب غير صالح');
    }
    final updated = await executor.update(
      DatabaseTables.accounts,
      {'balance': newBalance, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    if (updated == 0) throw Exception('الحساب مش موجود');
  }

  Future<void> updateAccount(Account account) async {
    _validateAccount(account);

    final db = await _database.database;
    final updated = await db.update(
      DatabaseTables.accounts,
      {
        'name': account.name.trim(),
        'type': account.type.name,
        'opening_balance': account.openingBalance,
        'balance': account.balance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
    if (updated == 0) throw Exception('الحساب مش موجود');
  }

  Future<void> deleteAccount(String id) async {
    final db = await _database.database;
    await db.delete(DatabaseTables.accounts, where: 'id = ?', whereArgs: [id]);
  }

  Account _fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => AccountType.other,
      ),
      openingBalance: (map['opening_balance'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
    );
  }
}
