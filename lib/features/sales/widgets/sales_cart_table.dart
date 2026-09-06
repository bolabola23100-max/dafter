import 'package:dafter/features/sales/model/cart_item.dart';
import 'package:flutter/material.dart';

class SalesCartTable extends StatelessWidget {
  final List<CartItem> cartItems;
  final void Function(int index) onIncreaseQuantity;
  final void Function(int index) onDecreaseQuantity;
  final void Function(int index) onRemoveItem;

  const SalesCartTable({
    super.key,
    required this.cartItems,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('السلة فارغة، أضف منتجات للفاتورة', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return DataTable(
      columnSpacing: 20,
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('الصنف')),
        DataColumn(label: Text('السعر')),
        DataColumn(label: Text('الكمية')),
        DataColumn(label: Text('الإجمالي')),
        DataColumn(label: Text('حذف')),
      ],
      rows: cartItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return DataRow(
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    item.sku,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text('${item.price.toStringAsFixed(2)} ر.س')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                    ),
                    onPressed: () => onDecreaseQuantity(index),
                  ),
                  Text('${item.quantity}'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => onIncreaseQuantity(index),
                  ),
                ],
              ),
            ),
            DataCell(Text('${item.total.toStringAsFixed(2)} ر.س')),
            DataCell(
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () => onRemoveItem(index),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
