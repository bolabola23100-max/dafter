import 'package:flutter/material.dart';

enum StockStatus { available, low, outOfStock }

class StockStatusBadge extends StatelessWidget {
  final StockStatus status;

  const StockStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case StockStatus.available:
        label = 'متوفر';
        bg = const Color(0xFFE6F4EA);
        fg = Colors.green;
        break;

      case StockStatus.low:
        label = 'منخفض';
        bg = const Color(0xFFFEF3E0);
        fg = Colors.orange;
        break;

      case StockStatus.outOfStock:
        label = 'نفدت الكمية';
        bg = const Color(0xFFFCE8E6);
        fg = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
