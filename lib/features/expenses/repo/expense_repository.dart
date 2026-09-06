import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/expense.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExpenseRepository {
  final AppDatabase _database;

  ExpenseRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  Future<void> addExpense(Expense expense) async {
    final db = await _database.database;
    await addExpenseWithExecutor(db, expense);
  }

  Future<void> addExpenseWithExecutor(DatabaseExecutor executor, Expense expense) async {
    await executor.insert(DatabaseTables.expenses, {
      'id': expense.id,
      'account_id': expense.accountId,
      'category': expense.category,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'notes': expense.notes,
    });
  }

  Future<List<Expense>> getExpenses() async {
    final db = await _database.database;
    final rows = await db.query(DatabaseTables.expenses, orderBy: 'date DESC');
    return rows.map(_fromMap).toList();
  }

  Expense _fromMap(Map<String, dynamic> row) {
    return Expense(
      id: row['id'] as String,
      accountId: row['account_id'] as String,
      category: row['category'] as String,
      amount: (row['amount'] as num).toDouble(),
      date: DateTime.parse(row['date'] as String),
      notes: row['notes'] as String?,
    );
  }
}
