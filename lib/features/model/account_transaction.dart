enum TransactionType {
  sale,
  purchase,
  payment,
  receipt,
  expense,
  transfer,
  adjustment,
}

class AccountTransaction {
  final String id;
  final String accountId;
  final TransactionType type;
  final double amount;
  final bool isDebit;
  final DateTime date;
  final String? referenceId;
  final String? description;

  AccountTransaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.isDebit,
    required this.date,
    this.referenceId,
    this.description,
  }) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Transaction amount must be a finite number greater than zero',
      );
    }
  }
}
