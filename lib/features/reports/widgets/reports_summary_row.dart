import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class ReportsSummaryRow extends StatelessWidget {
  final String totalRevenue;
  final String totalExpenses;
  final String netProfit;

  const ReportsSummaryRow({
    super.key,
    this.totalRevenue = '98,750.00 ريال',
    this.totalExpenses = '54,200.00 ريال',
    this.netProfit = '44,550.00 ريال',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.trending_up,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: totalRevenue,
            label: 'إجمالي الإيرادات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.trending_down,
            iconBg: const Color(0xFFF1F3F4),
            iconColor: Colors.grey,
            value: totalExpenses,
            label: 'إجمالي المصروفات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: netProfit,
            label: 'صافي الربح',
            trailingText: '+8.7% هذا الشهر',
          ),
        ),
      ],
    );
  }
}
