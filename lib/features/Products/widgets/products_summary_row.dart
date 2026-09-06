import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class ProductsSummaryRow extends StatelessWidget {
  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;

  const ProductsSummaryRow({
    super.key,
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.inventory_2_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: '$totalProducts منتج',
            label: 'إجمالي المنتجات',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: SummaryCard(
            icon: Icons.warning_amber_outlined,
            iconBg: const Color(0xFFFEF3E0),
            iconColor: Colors.orange[800]!,
            value: '$lowStockCount منتج',
            label: 'مخزون منخفض',
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: SummaryCard(
            icon: Icons.remove_circle_outline,
            iconBg: const Color(0xFFFCE8E6),
            iconColor: Colors.red[700]!,
            value: '$outOfStockCount منتجات',
            label: 'نفدت الكمية',
            trailingText: 'تحتاج إعادة طلب',
          ),
        ),
      ],
    );
  }
}
