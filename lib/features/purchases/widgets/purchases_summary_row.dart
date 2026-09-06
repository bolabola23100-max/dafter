import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class PurchasesSummaryRow extends StatelessWidget {
  final double totalPurchases;
  final int invoicesCount;
  final double totalPaid;
  final double totalRemaining;

  const PurchasesSummaryRow({
    super.key,
    required this.totalPurchases,
    required this.invoicesCount,
    required this.totalPaid,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.shopping_bag_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: '${totalPurchases.toStringAsFixed(2)} ج.م',
            label: 'إجمالي المشتريات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.receipt_long_outlined,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: '$invoicesCount فاتورة',
            label: 'عدد فواتير الشراء',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.payments_outlined,
            iconBg: const Color(0xFFEAF1F8),
            iconColor: const Color(0xFF35658A),
            value: '${totalPaid.toStringAsFixed(2)} ج.م',
            label: 'إجمالي المدفوع',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.money_off_outlined,
            iconBg: const Color(0xFFFDE8E8),
            iconColor: const Color(0xFFC53030),
            value: '${totalRemaining.toStringAsFixed(2)} ج.م',
            label: 'إجمالي المستحق',
          ),
        ),
      ],
    );
  }
}
