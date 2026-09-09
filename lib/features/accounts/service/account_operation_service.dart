import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/model/payment.dart';

class AccountOperationService {
  final AppDatabase _database;

  AccountOperationService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  Future<void> savePaymentOrReceipt({
    required PaymentType type,
    required String accountId,
    required double amount,
    String? personName,
    String? notes,
  }) async {
    if (accountId.trim().isEmpty) throw Exception('اختار الحساب الأول');
    if (amount <= 0) throw Exception('المبلغ لازم يكون أكبر من صفر');

    final db = await _database.database;

    await db.transaction((txn) async {
      final accountRows = await txn.query(
        DatabaseTables.accounts,
        where: 'id = ?',
        whereArgs: [accountId],
        limit: 1,
      );

      if (accountRows.isEmpty) throw Exception('الحساب مش موجود');

      final balance = (accountRows.first['balance'] as num).toDouble();
      if (type == PaymentType.payment && amount > balance) {
        throw Exception('الرصيد في الحساب مش كفاية');
      }

      final now = DateTime.now();
      final id = IdGenerator.generate();
      final newBalance = type == PaymentType.receipt
          ? balance + amount
          : balance - amount;

      await txn.insert(DatabaseTables.payments, {
        'id': id,
        'type': type.name,
        'person_type': null,
        'person_id': null,
        'account_id': accountId,
        'amount': amount,
        'date': now.toIso8601String(),
        'notes': notes,
      });

      await txn.insert(DatabaseTables.accountTransactions, {
        'id': IdGenerator.generate(),
        'account_id': accountId,
        'type': type == PaymentType.receipt
            ? TransactionType.receipt.name
            : TransactionType.payment.name,
        'amount': amount,
        'is_debit': type == PaymentType.payment ? 1 : 0,
        'date': now.toIso8601String(),
        'reference_id': id,
        'description': personName?.trim().isNotEmpty == true
            ? personName!.trim()
            : null,
      });

      await txn.update(
        DatabaseTables.accounts,
        {'balance': newBalance, 'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [accountId],
      );
    });
  }
}
