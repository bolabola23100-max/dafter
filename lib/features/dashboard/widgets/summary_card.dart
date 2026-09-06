import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String? trailingText;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    this.trailingText,
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                if (trailingText != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(
                        trailingText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}