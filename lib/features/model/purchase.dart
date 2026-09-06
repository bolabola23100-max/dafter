import 'purchase_item.dart';

class Purchase {
  final String id;
  final String? supplierId;

  final DateTime date;

  List<PurchaseItem> items;

  double discount;
  double paidAmount;

  String? notes;

  Purchase({
    required this.id,
    this.supplierId,
    required this.date,
    required this.items,
    this.discount = 0,
    this.paidAmount = 0,
    this.notes,
  });

  double get subtotal {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get total {
    return subtotal - discount;
  }

  double get remainingAmount {
    return total - paidAmount;
  }
}
