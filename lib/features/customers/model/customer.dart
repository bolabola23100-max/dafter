class Customer {
  final String name;
  final String phone;
  final double totalPurchases;
  final double paid;

  Customer({
    required this.name,
    required this.phone,
    required this.totalPurchases,
    required this.paid,
  });

  double get remaining => totalPurchases - paid;
}
