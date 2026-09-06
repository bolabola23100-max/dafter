import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class SuppliersSummaryRow extends StatelessWidget {
  final int totalSuppliers;
  final double totalDue;
  final double monthlyPurchases;

  const SuppliersSummaryRow({
    super.key,
    required this.totalSuppliers,
    this.totalDue = 22400.00,
    this.monthlyPurchases = 92400.00,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.store_outlined,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: '$totalSuppliers مورد',
            label: 'إجمالي الموردين',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.money_off_outlined,
            iconBg: const Color(0xFFFDE8E8),
            iconColor: const Color(0xFFC53030),
            value: '${totalDue.toStringAsFixed(2)} ج.م',
            label: 'إجمالي المستحقات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.shopping_bag_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: '${monthlyPurchases.toStringAsFixed(2)} ج.م',
            label: 'مشتريات الشهر',
            trailingText: '+1.5% عن الشهر الماضي',
          ),
        ),
      ],
    );
  }
}
