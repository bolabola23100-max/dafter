class Supplier {
  final String id;
  String name;
  String? phone;
  String? address;
  String? notes;

  double openingBalance;
  double balance;

  Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.openingBalance = 0,
    this.balance = 0,
  });
}
