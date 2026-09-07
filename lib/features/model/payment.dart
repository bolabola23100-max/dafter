enum PaymentType {
  receipt, // قبض
  payment, // دفع
}

class Payment {
  final String id;
  final PaymentType type;
  final String? personId;
  final String accountId;
  final double amount;
  final DateTime date;
  final String? notes;

  Payment({
    required this.id,
    required this.type,
    this.personId,
    required this.accountId,
    required this.amount,
    required this.date,
    this.notes,
  }) : assert(amount > 0, 'Payment amount must be greater than zero');
}
