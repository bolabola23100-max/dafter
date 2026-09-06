import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';

class JournalEntryService {
  final AppDatabase _database;
  final AccountRepository _accountRepository;
  final AccountTransactionRepository _transactionRepository;

  JournalEntryService({
    AppDatabase? database,
    AccountRepository? accountRepository,
    AccountTransactionRepository? transactionRepository,
  }) : _database = database ?? AppDatabase.instance,
       _accountRepository = accountRepository ?? AccountRepository(),
       _transactionRepository =
           transactionRepository ?? AccountTransactionRepository();

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> saveEntry({
    required String debitAccountId,
    required String creditAccountId,
    required double amount,
    required String description,
    DateTime? date,
  }) async {
    if (debitAccountId == creditAccountId) {
      throw Exception('مينفعش تختار نفس الحساب في الطرفين');
    }
    if (amount <= 0) {
      throw Exception('أدخل مبلغ صحيح');
    }
    if (description.trim().isEmpty) {
      throw Exception('أدخل وصف القيد');
    }

    final db = await _database.database;

    await db.transaction((txn) async {
      final debitAccount = await _accountRepository.getAccountByIdWithExecutor(
        txn,
        debitAccountId,
      );
      final creditAccount = await _accountRepository.getAccountByIdWithExecutor(
        txn,
        creditAccountId,
      );

      if (debitAccount == null) {
        throw Exception('الحساب المدين مش موجود');
      }
      if (creditAccount == null) {
        throw Exception('الحساب الدائن مش موجود');
      }
      if (creditAccount.balance < amount) {
        throw Exception('رصيد الحساب الدائن مش مكفي');
      }

      final entryId = _newId();
      final now = date ?? DateTime.now();

      await _transactionRepository.addTransactionWithExecutor(
        txn,
        AccountTransaction(
          id: _newId(),
          accountId: debitAccount.id,
          type: TransactionType.adjustment,
          amount: amount,
          isDebit: false,
          date: now,
          referenceId: entryId,
          description: description.trim(),
        ),
      );

      await _transactionRepository.addTransactionWithExecutor(
        txn,
        AccountTransaction(
          id: _newId(),
          accountId: creditAccount.id,
          type: TransactionType.adjustment,
          amount: amount,
          isDebit: true,
          date: now,
          referenceId: entryId,
          description: description.trim(),
        ),
      );

      await _accountRepository.updateBalanceWithExecutor(
        txn,
        debitAccount.id,
        debitAccount.balance + amount,
      );

      await _accountRepository.updateBalanceWithExecutor(
        txn,
        creditAccount.id,
        creditAccount.balance - amount,
      );
    });
  }
}
