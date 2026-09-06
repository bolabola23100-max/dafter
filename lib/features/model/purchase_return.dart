class PurchaseReturn {
  final String id;
  final String purchaseId;
  final String? supplierId;
  final DateTime date;
  final List<PurchaseReturnItem> items;
  final double refundedAmount;
  final String? notes;

  PurchaseReturn({
    required this.id,
    required this.purchaseId,
    this.supplierId,
    required this.date,
    required this.items,
    this.refundedAmount = 0,
    this.notes,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);
}

class PurchaseReturnItem {
  final String id;
  final String returnId;
  final String purchaseItemId;
  final String productId;
  final int quantity;
  final double price;

  PurchaseReturnItem({
    required this.id,
    required this.returnId,
    required this.purchaseItemId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}
