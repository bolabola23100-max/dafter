class Product {
  final String id;
  String name;
  String? barcode;
  String? categoryId;

  double purchasePrice;
  double sellingPrice;

  int quantity;
  int minQuantity;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    required this.purchasePrice,
    required this.sellingPrice,
    this.quantity = 0,
    this.minQuantity = 0,
  });
}
