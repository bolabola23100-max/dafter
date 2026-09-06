enum AccountType { cash, bank, expense, income, other }

class Account {
  final String id;
  String name;
  AccountType type;

  double openingBalance;
  double balance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.openingBalance = 0,
    this.balance = 0,
  });
}
