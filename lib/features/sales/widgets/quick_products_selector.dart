import 'package:dafter/features/sales/model/cart_item.dart';
import 'package:flutter/material.dart';

class QuickProductsSelector extends StatelessWidget {
  final List<CartItem> availableProducts;
  final ValueChanged<CartItem> onProductSelected;

  const QuickProductsSelector({
    super.key,
    required this.availableProducts,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اضغط على المنتج لإضافته للفاتورة مباشرة',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableProducts.map((product) {
            return ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(
                '${product.productName} — ${product.price.toStringAsFixed(0)} ر.س',
              ),
              onPressed: () => onProductSelected(product),
            );
          }).toList(),
        ),
      ],
    );
  }
}
