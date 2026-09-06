class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;

  int quantity;
  double price;
  double discount;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  double get subtotal {
    return (quantity * price) - discount;
  }
}