class Customer {
  final String id;
  String name;
  String? phone;
  String? address;

  double openingBalance;
  double balance;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.openingBalance = 0,
    this.balance = 0,
  });
}