import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AccountTransactionRepository {
  final AppDatabase _database;

  AccountTransactionRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  Future<void> addTransaction(AccountTransaction transaction) async {
    final db = await _database.database;
    await addTransactionWithExecutor(db, transaction);
  }

  Future<void> addTransactionWithExecutor(
    DatabaseExecutor executor,
    AccountTransaction transaction,
  ) async {
    if (transaction.amount <= 0) throw Exception('قيمة الحركة لازم تكون أكبر من صفر');
    await executor.insert(DatabaseTables.accountTransactions, {
      'id': transaction.id,
      'account_id': transaction.accountId,
      'type': transaction.type.name,
      'amount': transaction.amount,
      'is_debit': transaction.isDebit ? 1 : 0,
      'date': transaction.date.toIso8601String(),
      'reference_id': transaction.referenceId,
      'description': transaction.description,
    });
  }

  Future<List<AccountTransaction>> getTransactions() async {
    final db = await _database.database;
    final result = await db.query(DatabaseTables.accountTransactions, orderBy: 'date DESC');
    return result.map(_fromMap).toList();
  }

  Future<List<AccountTransaction>> getAccountTransactions(String accountId) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.accountTransactions,
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return result.map(_fromMap).toList();
  }

  Future<AccountTransaction?> getTransactionById(String id) async {
    final db = await _database.database;
    final result = await db.query(
      DatabaseTables.accountTransactions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return _fromMap(result.first);
  }

  AccountTransaction _fromMap(Map<String, dynamic> map) {
    return AccountTransaction(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      type: TransactionType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => TransactionType.adjustment,
      ),
      amount: (map['amount'] as num).toDouble(),
      isDebit: (map['is_debit'] as int) == 1,
      date: DateTime.parse(map['date'] as String),
      referenceId: map['reference_id'] as String?,
      description: map['description'] as String?,
    );
  }
}
