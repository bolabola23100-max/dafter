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
  }) : assert(amount > 0, 'Transaction amount must be greater than zero');
}
