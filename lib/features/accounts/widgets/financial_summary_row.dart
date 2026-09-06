import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class FinancialSummaryRow extends StatelessWidget {
  const FinancialSummaryRow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: '45,000.00 ريال',
            label: 'الرصيد الكلي',
          ),
        ),
    
        const SizedBox(width: 16),
    
        Expanded(
          child: SummaryCard(
            icon: Icons.arrow_upward_outlined,
            iconBg: const Color(0xFFF1F3F4),
            iconColor: Colors.grey,
            value: '12,300.00 ريال',
            label: 'إجمالي المقبوضات',
          ),
        ),
    
        const SizedBox(width: 16),
    
        Expanded(
          child: SummaryCard(
            icon: Icons.arrow_downward_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: '7,650.00 ريال',
            label: 'إجمالي المدفوعات',
            trailingText: '-4.3% عن الأمس',
          ),
        ),
      ],
    );
  }
}
