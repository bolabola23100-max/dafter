import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:flutter/material.dart';

class SettingsSummaryRow extends StatelessWidget {
  final int activeUsers;
  final String dbSize;
  final String appVersion;

  const SettingsSummaryRow({
    super.key,
    this.activeUsers = 5,
    this.dbSize = '1.2 GB',
    this.appVersion = 'v2.4.1',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.people_outlined,
            iconBg: const Color(0xFFF3E9DD),
            iconColor: const Color(0xFF9C6B30),
            value: '$activeUsers مستخدمين',
            label: 'المستخدمون النشطون',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.storage_outlined,
            iconBg: const Color(0xFFF1F3F4),
            iconColor: Colors.grey[700]!,
            value: dbSize,
            label: 'حجم قاعدة البيانات',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            icon: Icons.update_outlined,
            iconBg: const Color(0xFFDDEDEC),
            iconColor: const Color(0xFF0E4C4C),
            value: appVersion,
            label: 'إصدار التطبيق',
            trailingText: 'آخر تحديث اليوم',
          ),
        ),
      ],
    );
  }
}
