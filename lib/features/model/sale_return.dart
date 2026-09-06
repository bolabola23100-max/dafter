class SaleReturn {
  final String id;
  final String saleId;
  final String? customerId;
  final DateTime date;
  final List<SaleReturnItem> items;
  final double refundedAmount;
  final String? notes;

  SaleReturn({
    required this.id,
    required this.saleId,
    this.customerId,
    required this.date,
    required this.items,
    this.refundedAmount = 0,
    this.notes,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);

  double get creditAmount {
    final value = total - refundedAmount;
    return value < 0 ? 0 : value;
  }
}

class SaleReturnItem {
  final String id;
  final String returnId;
  final String saleItemId;
  final String productId;
  final int quantity;
  final double price;

  SaleReturnItem({
    required this.id,
    required this.returnId,
    required this.saleItemId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
