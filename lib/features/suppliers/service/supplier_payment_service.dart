import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SupplierPaymentService {
  final AppDatabase _database;
  final SupplierRepository _supplierRepository;
  final AccountRepository _accountRepository;
  final PaymentRepository _paymentRepository;
  final AccountTransactionRepository _accountTransactionRepository;

  SupplierPaymentService({
    AppDatabase? database,
    SupplierRepository? supplierRepository,
    AccountRepository? accountRepository,
    PaymentRepository? paymentRepository,
    AccountTransactionRepository? accountTransactionRepository,
  })  : _database = database ?? AppDatabase.instance,
        _supplierRepository = supplierRepository ?? SupplierRepository(),
        _accountRepository = accountRepository ?? AccountRepository(),
        _paymentRepository = paymentRepository ?? PaymentRepository(),
        _accountTransactionRepository =
            accountTransactionRepository ?? AccountTransactionRepository();

  Future<void> paySupplier({
    required String supplierId,
    required String accountId,
    required double amount,
    DateTime? date,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('مبلغ الدفعة يجب أن يكون أكبر من صفر');
    }

    final db = await _database.database;
    final paymentDate = date ?? DateTime.now();

    await db.transaction((txn) async {
      final supplier = await _supplierRepository.getSupplierByIdWithExecutor(
        txn,
        supplierId,
      );
      if (supplier == null) throw Exception('المورد غير موجود');

      if (amount > supplier.balance) {
        throw Exception('مبلغ الدفعة أكبر من المستحق على المورد');
      }

      final account = await _accountRepository.getAccountByIdWithExecutor(
        txn,
        accountId,
      );
      if (account == null) throw Exception('الحساب غير موجود');

      if (amount > account.balance) {
        throw Exception('رصيد الحساب غير كافٍ');
      }

      final id = _generateId();

      await _paymentRepository.addPaymentWithExecutor(
        txn,
        Payment(
          id: id,
          type: PaymentType.payment,
          personId: supplierId,
          accountId: accountId,
          amount: amount,
          date: paymentDate,
          notes: notes,
        ),
      );

      await _accountTransactionRepository.addTransactionWithExecutor(
        txn,
        AccountTransaction(
          id: _generateId(),
          accountId: accountId,
          type: TransactionType.payment,
          amount: amount,
          isDebit: true,
          date: paymentDate,
          referenceId: id,
          description: 'سداد دفعة للمورد: ${supplier.name}',
        ),
      );

      await _supplierRepository.updateBalanceWithExecutor(
        txn,
        supplierId,
        supplier.balance - amount,
      );

      await _accountRepository.updateBalanceWithExecutor(
        txn,
        accountId,
        account.balance - amount,
      );
    });
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
