import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class FinancialSummaryRow extends StatelessWidget {
  final double totalBalance;
  final double totalReceipts;
  final double totalPayments;

  const FinancialSummaryRow({
    super.key,
    required this.totalBalance,
    required this.totalReceipts,
    required this.totalPayments,
  });

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: _money(totalBalance),
            label: 'الرصيد الكلي',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.arrow_downward_outlined,
            iconBg: const Color(0xFFF1F3F4),
            iconColor: Colors.grey,
            value: _money(totalReceipts),
            label: 'إجمالي القبض',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.arrow_upward_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: _money(totalPayments),
            label: 'إجمالي الدفع',
          ),
        ),
      ],
    );
  }
}
