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
  }) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Payment amount must be a finite number greater than zero',
      );
    }
  }
}
