enum StockMovementType {
  purchase,
  sale,
  purchaseReturn,
  saleReturn,
  adjustment,
}

class StockMovement {
  final String id;

  final String productId;

  final StockMovementType type;

  final int quantity;

  final DateTime date;

  final String? referenceId;

  final String? notes;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.date,
    this.referenceId,
    this.notes,
  });
}
