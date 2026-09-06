import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/purchases/widgets/purchases_invoice_row.dart';
import 'package:flutter/material.dart';

class PurchasesTable extends StatelessWidget {
  final List<Purchase> invoices;
  final void Function(Purchase) onInvoiceTap;

  const PurchasesTable({
    super.key,
    required this.invoices,
    required this.onInvoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 45, color: Colors.grey),

            SizedBox(height: 12),

            Text(
              'لا توجد فواتير',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 5),

            Text(
              'لم يتم العثور على فواتير مطابقة للبحث',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'الفاتورة',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  'المورد',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'الأصناف',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'الإجمالي',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'المتبقي',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              Expanded(
                child: Text(
                  'التاريخ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              SizedBox(width: 45, child: Text('')),
            ],
          ),
        ),

        ...invoices.map(
          (invoice) => PurchasesInvoiceRow(
            invoice: invoice,
            onTap: () => onInvoiceTap(invoice),
          ),
        ),
      ],
    );
  }
}
