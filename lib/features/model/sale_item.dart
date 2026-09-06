class SaleItem {
  final String id;
  final String saleId;
  final String productId;

  int quantity;
  double price;
  double discount;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  double get subtotal {
    return (quantity * price) - discount;
  }
}
