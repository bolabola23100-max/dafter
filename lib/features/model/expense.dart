class Expense {
  final String id;

  final String accountId;

  final String category;

  final double amount;

  final DateTime date;

  final String? notes;

  Expense({
    required this.id,
    required this.accountId,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });
}
