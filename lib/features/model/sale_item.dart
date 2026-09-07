class SaleItem {
  final String id;
  final String saleId;
  final String productId;

  int quantity;
  double price;
  double discount;
  double costPrice;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.discount = 0,
    this.costPrice = 0,
  });

  double get subtotal => (quantity * price) - discount;
  double get costTotal => quantity * costPrice;
}
