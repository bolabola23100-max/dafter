import 'package:flutter/material.dart';
import 'package:dafter/features/model/category.dart';

class ProductsFilterBar extends StatelessWidget {
  final List<Category> categories;

  final String? selectedCategory;
  final String? selectedStatus;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onReset;

  const ProductsFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'التصنيف',
                isDense: true,
              ),
              hint: const Text('كل التصنيفات'),

              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),

              onChanged: onCategoryChanged,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'حالة المخزون',
                isDense: true,
              ),
              hint: const Text('كل الحالات'),

              items: const [
                DropdownMenuItem(value: 'available', child: Text('متوفر')),
                DropdownMenuItem(value: 'low', child: Text('منخفض')),
                DropdownMenuItem(
                  value: 'outOfStock',
                  child: Text('نفدت الكمية'),
                ),
              ],

              onChanged: onStatusChanged,
            ),
          ),

          const SizedBox(width: 16),

          ElevatedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }
}
