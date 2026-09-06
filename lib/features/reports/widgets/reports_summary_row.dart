import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class ReportsSummaryRow extends StatelessWidget {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  const ReportsSummaryRow({
    super.key,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
  });

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.trending_up,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: _money(totalRevenue),
            label: 'صافي المبيعات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.trending_down,
            iconBg: const Color(0xFFF1F3F4),
            iconColor: Colors.grey,
            value: _money(totalExpenses),
            label: 'إجمالي المصروفات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: _money(netProfit),
            label: 'صافي الحركة',
          ),
        ),
      ],
    );
  }
}
