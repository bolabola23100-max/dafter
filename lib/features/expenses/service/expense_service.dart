import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/expenses/repo/expense_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/expense.dart';

class ExpenseService {
  final AppDatabase _database;
  final ExpenseRepository _expenseRepository;
  final AccountRepository _accountRepository;
  final AccountTransactionRepository _transactionRepository;

  ExpenseService({
    AppDatabase? database,
    ExpenseRepository? expenseRepository,
    AccountRepository? accountRepository,
    AccountTransactionRepository? transactionRepository,
  })  : _database = database ?? AppDatabase.instance,
        _expenseRepository = expenseRepository ?? ExpenseRepository(),
        _accountRepository = accountRepository ?? AccountRepository(),
        _transactionRepository = transactionRepository ?? AccountTransactionRepository();

  Future<void> createExpense(Expense expense) async {
    if (!expense.amount.isFinite || expense.amount <= 0) {
      throw Exception('المبلغ لازم يكون أكبر من صفر');
    }
    if (expense.category.trim().isEmpty) throw Exception('اكتب نوع المصروف');

    final db = await _database.database;
    await db.transaction((txn) async {
      final account = await _accountRepository.getAccountByIdWithExecutor(txn, expense.accountId);
      if (account == null) throw Exception('الحساب مش موجود');
      if (!account.balance.isFinite) throw Exception('رصيد الحساب غير صالح');
      if (account.balance < expense.amount) throw Exception('رصيد الحساب مش مكفي');

      final newBalance = account.balance - expense.amount;
      if (!newBalance.isFinite) throw Exception('الرصيد الناتج غير صالح');

      await _expenseRepository.addExpenseWithExecutor(txn, expense);
      await _transactionRepository.addTransactionWithExecutor(
        txn,
        AccountTransaction(
          id: IdGenerator.generate(),
          accountId: account.id,
          type: TransactionType.payment,
          amount: expense.amount,
          isDebit: true,
          date: expense.date,
          referenceId: expense.id,
          description: 'مصروف: ${expense.category}',
        ),
      );
      await _accountRepository.updateBalanceWithExecutor(
        txn,
        account.id,
        newBalance,
      );
    });
  }
}
