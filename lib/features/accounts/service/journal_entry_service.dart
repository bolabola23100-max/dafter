import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/utils/id_generator.dart';
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

  Future<void> saveEntry({
    required String debitAccountId,
    required String creditAccountId,
    required double amount,
    required String description,
    DateTime? date,
  }) async {
    if (debitAccountId.trim().isEmpty || creditAccountId.trim().isEmpty) {
      throw Exception('اختار الحسابين الأول');
    }
    if (debitAccountId == creditAccountId) {
      throw Exception('مينفعش تختار نفس الحساب في الطرفين');
    }
    if (!amount.isFinite || amount <= 0) {
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
      if (!debitAccount.balance.isFinite || !creditAccount.balance.isFinite) {
        throw Exception('رصيد أحد الحسابات غير صالح');
      }
      if (creditAccount.balance < amount) {
        throw Exception('رصيد الحساب الدائن مش مكفي');
      }

      final entryId = IdGenerator.generate();
      final now = date ?? DateTime.now();
      final cleanDescription = description.trim();
      final newDebitBalance = debitAccount.balance + amount;
      final newCreditBalance = creditAccount.balance - amount;
      if (!newDebitBalance.isFinite || !newCreditBalance.isFinite) {
        throw Exception('الرصيد الناتج غير صالح');
      }

      await _transactionRepository.addTransactionWithExecutor(
        txn,
        AccountTransaction(
          id: IdGenerator.generate(),
          accountId: debitAccount.id,
          type: TransactionType.adjustment,
          amount: amount,
          isDebit: false,
          date: now,
          referenceId: entryId,
          description: cleanDescription,
        ),
      );

      await _transactionRepository.addTransactionWithExecutor(
        txn,
        AccountTransaction(
          id: IdGenerator.generate(),
          accountId: creditAccount.id,
          type: TransactionType.adjustment,
          amount: amount,
          isDebit: true,
          date: now,
          referenceId: entryId,
          description: cleanDescription,
        ),
      );

      await _accountRepository.updateBalanceWithExecutor(
        txn,
        debitAccount.id,
        newDebitBalance,
      );

      await _accountRepository.updateBalanceWithExecutor(
        txn,
        creditAccount.id,
        newCreditBalance,
      );
    });
  }
}
