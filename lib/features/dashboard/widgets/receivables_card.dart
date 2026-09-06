import 'package:flutter/material.dart';

class ReceivablesCard extends StatelessWidget {
  final String customerDue;
  final String supplierDue;

  const ReceivablesCard({
    super.key,
    required this.customerDue,
    required this.supplierDue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E9DD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF9C6B30),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'المستحقات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _DueItem(
                  title: 'لنا عند العملاء',
                  value: customerDue,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF0E4C4C),
                  iconBg: const Color(0xFFDDEDEC),
                  onTap: () {},
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _DueItem(
                  title: 'علينا للموردين',
                  value: supplierDue,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFC53030),
                  iconBg: const Color(0xFFFDE8E8),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DueItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _DueItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E9EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 19),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
