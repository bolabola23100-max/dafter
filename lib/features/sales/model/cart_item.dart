class CartItem {
  final String productName;
  final String sku;
  final double price;
  int quantity;

  CartItem({
    required this.productName,
    required this.sku,
    required this.price,
    this.quantity = 1,
  });

  double get total => price * quantity;
}
