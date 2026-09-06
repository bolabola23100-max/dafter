import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';

class CustomerPaymentService {
  final AppDatabase _database = AppDatabase.instance;
  final CustomerRepository _customerRepository = CustomerRepository();
  final AccountRepository _accountRepository = AccountRepository();

  Future<void> receivePayment({
    required String customerId,
    required String accountId,
    required double amount,
    String? notes,
  }) async {
    if (amount <= 0) throw Exception('المبلغ لازم يكون أكبر من صفر');

    final db = await _database.database;
    await db.transaction((txn) async {
      final customer = await _customerRepository.getCustomerByIdWithExecutor(txn, customerId);
      if (customer == null) throw Exception('العميل مش موجود');
      if (amount > customer.balance) throw Exception('المبلغ أكبر من اللي على العميل');

      final account = await _accountRepository.getAccountByIdWithExecutor(txn, accountId);
      if (account == null) throw Exception('الحساب مش موجود');

      final paymentId = DateTime.now().microsecondsSinceEpoch.toString();
      final now = DateTime.now();
      final payment = Payment(
        id: paymentId,
        type: PaymentType.receipt,
        personId: customerId,
        accountId: accountId,
        amount: amount,
        date: now,
        notes: notes,
      );

      await txn.insert(DatabaseTables.payments, {
        'id': payment.id,
        'type': payment.type.name,
        'person_type': 'customer',
        'person_id': payment.personId,
        'account_id': payment.accountId,
        'amount': payment.amount,
        'date': payment.date.toIso8601String(),
        'notes': payment.notes,
      });

      final transaction = AccountTransaction(
        id: '${paymentId}_txn',
        accountId: accountId,
        type: TransactionType.receipt,
        amount: amount,
        isDebit: false,
        date: now,
        referenceId: paymentId,
        description: 'تحصيل من ${customer.name}',
      );

      await txn.insert(DatabaseTables.accountTransactions, {
        'id': transaction.id,
        'account_id': transaction.accountId,
        'type': transaction.type.name,
        'amount': transaction.amount,
        'is_debit': transaction.isDebit ? 1 : 0,
        'date': transaction.date.toIso8601String(),
        'reference_id': transaction.referenceId,
        'description': transaction.description,
      });

      await _customerRepository.updateBalanceWithExecutor(txn, customerId, customer.balance - amount);
      await _accountRepository.updateBalanceWithExecutor(txn, accountId, account.balance + amount);
    });
  }
}
