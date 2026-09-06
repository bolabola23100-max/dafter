import 'package:dafter/features/model/supplier.dart';
import 'package:flutter/material.dart';

class SupplierRow extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;

  const SupplierRow({super.key, required this.supplier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasBalance = supplier.balance > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F1F2))),
        ),
        child: Row(
          children: [
            // =======================================================
            // Supplier
            // =======================================================
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E9DD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_outlined,
                      size: 18,
                      color: Color(0xFF9C6B30),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      supplier.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // =======================================================
            // Phone
            // =======================================================
            Expanded(
              child: Text(
                supplier.phone ?? '-',
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            // =======================================================
            // Balance
            // =======================================================
            Expanded(
              child: Text(
                '${supplier.balance.toStringAsFixed(2)} ج.م',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasBalance
                      ? const Color(0xFFC53030)
                      : const Color(0xFF0E4C4C),
                ),
              ),
            ),

            // =======================================================
            // Status
            // =======================================================
            Expanded(
              child: Text(
                hasBalance ? 'عليه مستحقات' : 'لا يوجد مستحقات',
                style: TextStyle(
                  fontSize: 12,
                  color: hasBalance ? const Color(0xFFC53030) : Colors.grey,
                ),
              ),
            ),

            // =======================================================
            // More
            // =======================================================
            SizedBox(
              width: 45,
              child: IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.more_horiz, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
