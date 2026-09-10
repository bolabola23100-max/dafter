import 'package:dafter/features/model/purchase.dart';
import 'package:flutter/material.dart';

class PurchaseInvoiceMenuSheet extends StatelessWidget {
  final Purchase invoice;
  final VoidCallback onView;
  final VoidCallback onPdf;
  final VoidCallback onPrint;
  final VoidCallback onReturn;

  const PurchaseInvoiceMenuSheet({
    super.key,
    required this.invoice,
    required this.onView,
    required this.onPdf,
    required this.onPrint,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
      const SizedBox(height: 20),
      Text('فاتورة #${invoice.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(invoice.supplierId ?? 'بدون مورد', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      ListTile(onTap: onView, leading: const Icon(Icons.visibility_outlined), title: const Text('عرض الفاتورة')),
      ListTile(onTap: onPdf, leading: const Icon(Icons.picture_as_pdf_outlined), title: const Text('حفظ PDF')),
      ListTile(onTap: onPrint, leading: const Icon(Icons.print_outlined), title: const Text('طباعة')),
      ListTile(onTap: onReturn, leading: const Icon(Icons.assignment_return_outlined), title: const Text('مرتجع من الفاتورة')),
    ])));
  }
}
