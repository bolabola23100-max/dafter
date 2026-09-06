enum PaymentType {
  receipt, // قبض
  payment, // دفع
}

class Payment {
  final String id;

  final PaymentType type;

  /// العميل أو المورد أو أي شخص مرتبط بالدفعة
  final String? personId;

  /// الحساب اللي دخلت/خرجت منه الفلوس
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
  });
}
