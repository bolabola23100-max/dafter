import 'package:flutter/material.dart';

class ReportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String operations;
  final String amount;
  final String status;

  const ReportRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.operations,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E9EB))),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF555555)),
          ),

          const SizedBox(width: 12),

          // Name
          Expanded(
            flex: 2,
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Operations
          Expanded(
            child: Text(
              operations,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          // Amount
          Expanded(
            child: Text(
              amount,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          // Status
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
