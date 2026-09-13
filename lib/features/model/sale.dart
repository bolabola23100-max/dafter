import 'sale_item.dart';

enum PaymentStatus { paid, partial, unpaid }

class Sale {
  final String id;
  final int? invoiceNumber;
  final String? customerId;

  final DateTime date;

  List<SaleItem> items;

  double discount;
  double paidAmount;

  PaymentStatus paymentStatus;

  String? notes;

  Sale({
    required this.id,
    this.invoiceNumber,
    this.customerId,
    required this.date,
    required this.items,
    this.discount = 0,
    this.paidAmount = 0,
    this.paymentStatus = PaymentStatus.unpaid,
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

  String get displayInvoiceNumber =>
      invoiceNumber == null ? 'فاتورة بيع' : 'فاتورة بيع $invoiceNumber';
}
