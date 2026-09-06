import 'package:flutter/material.dart';

class InventoryStatusCard extends StatelessWidget {
  final int totalProducts;
  final int lowStock;
  final int outOfStock;

  const InventoryStatusCard({
    super.key,
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
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
              const Icon(Icons.inventory_2_outlined, size: 20),
              const SizedBox(width: 8),
              const Text(
                'حالة المخزون',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('عرض المخزون')),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _InventoryItem(
                  icon: Icons.inventory_2_outlined,
                  value: totalProducts.toString(),
                  label: 'إجمالي المنتجات',
                  iconBg: const Color(0xFFF1F3F4),
                  iconColor: Colors.grey,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _InventoryItem(
                  icon: Icons.warning_amber_outlined,
                  value: lowStock.toString(),
                  label: 'منخفض المخزون',
                  iconBg: const Color(0xFFFFF3DD),
                  iconColor: const Color(0xFFB7791F),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _InventoryItem(
                  icon: Icons.remove_shopping_cart_outlined,
                  value: outOfStock.toString(),
                  label: 'نافد المخزون',
                  iconBg: const Color(0xFFFDE8E8),
                  iconColor: const Color(0xFFC53030),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconBg;
  final Color iconColor;

  const _InventoryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
