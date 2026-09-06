import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String account;
  final String date;
  final String amount;
  final Color amountColor;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.account,
    required this.date,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(width: 14),

          // Transaction Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Account
          SizedBox(
            width: 110,
            child: Text(
              account,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          // Date
          SizedBox(
            width: 130,
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          // Amount
          SizedBox(
            width: 130,
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
