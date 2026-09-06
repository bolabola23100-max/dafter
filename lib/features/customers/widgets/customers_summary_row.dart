import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class CustomersSummaryRow extends StatelessWidget {
  final int totalCustomers;
  final double totalDebt;
  final int newCustomersToday;

  const CustomersSummaryRow({
    super.key,
    required this.totalCustomers,
    this.totalDebt = 0,
    this.newCustomersToday = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SummaryCard(icon: Icons.people_outlined, iconBg: const Color(0xFFF3E9DD), iconColor: const Color(0xFF9C6B30), value: '$totalCustomers عميل', label: 'إجمالي العملاء')),
        const SizedBox(width: 16),
        Expanded(child: SummaryCard(icon: Icons.money_off_outlined, iconBg: const Color(0xFFF1F3F4), iconColor: Colors.grey, value: '${totalDebt.toStringAsFixed(2)} جنيه', label: 'إجمالي اللي عليهم')),
        const SizedBox(width: 16),
        Expanded(child: SummaryCard(icon: Icons.trending_up, iconBg: const Color(0xFFDDEDEC), iconColor: const Color(0xFF0E4C4C), value: '$newCustomersToday عملاء', label: 'عملاء جدد النهارده')),
      ],
    );
  }
}
