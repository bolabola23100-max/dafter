import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PaymentRepository {
  final AppDatabase _database;

  PaymentRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  Future<void> addPayment(Payment payment) async {
    final db = await _database.database;

    await addPaymentWithExecutor(db, payment);
  }

  Future<void> addPaymentWithExecutor(
    DatabaseExecutor executor,
    Payment payment,
  ) async {
    await executor.insert(DatabaseTables.payments, {
      'id': payment.id,
      'type': payment.type.name,
      'person_type': null,
      'person_id': payment.personId,
      'account_id': payment.accountId,
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'notes': payment.notes,
    });
  }

  Future<List<Payment>> getPayments() async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.payments,
      orderBy: 'date DESC',
    );

    return result.map(_fromMap).toList();
  }

  Future<List<Payment>> getPaymentsByPerson(String personId) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.payments,
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'date DESC',
    );

    return result.map(_fromMap).toList();
  }

  Future<Payment?> getPaymentById(String id) async {
    final db = await _database.database;

    final result = await db.query(
      DatabaseTables.payments,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return _fromMap(result.first);
  }

  Future<void> deletePayment(String id) async {
    final db = await _database.database;

    await db.delete(DatabaseTables.payments, where: 'id = ?', whereArgs: [id]);
  }

  Payment _fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      type: PaymentType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => PaymentType.payment,
      ),
      personId: map['person_id'] as String?,
      accountId: map['account_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }
}
