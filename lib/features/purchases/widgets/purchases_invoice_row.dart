import 'package:dafter/features/model/purchase.dart';
import 'package:flutter/material.dart';

class PurchasesInvoiceRow extends StatelessWidget {
  final Purchase invoice;
  final VoidCallback onTap;

  const PurchasesInvoiceRow({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F1F2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '#${invoice.id}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Expanded(flex: 2, child: Text(invoice.supplierId ?? '-')),

            Expanded(child: Text('${invoice.items.length} صنف')),

            Expanded(
              child: Text(
                '${invoice.total.toStringAsFixed(2)} ج.م',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Expanded(
              child: Text(
                invoice.remainingAmount <= 0
                    ? 'مدفوع'
                    : '${invoice.remainingAmount.toStringAsFixed(2)} ج.م',
                style: TextStyle(
                  color: invoice.remainingAmount <= 0
                      ? const Color(0xFF0E4C4C)
                      : const Color(0xFFC53030),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Expanded(
              child: Text(
                _formatDate(invoice.date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

            SizedBox(
              width: 45,
              child: IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.more_horiz, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
