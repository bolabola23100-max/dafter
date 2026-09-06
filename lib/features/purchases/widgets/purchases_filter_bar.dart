import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class PurchasesFilterBar extends StatelessWidget {
  final String selectedFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<String> onSearchChanged;
  final int count;

  const PurchasesFilterBar({
    super.key,
    required this.selectedFilter,
    required this.searchController,
    required this.onFilterSelected,
    required this.onSearchChanged,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['الكل', 'نقدي', 'آجل', 'غير مكتمل'];

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'فواتير الشراء',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: 260,
              height: 40,
              child: CustomTextFormField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'رقم الفاتورة أو اسم المورد...',
                  prefixIcon: const Icon(Icons.search, size: 19),
                  filled: true,
                  fillColor: const Color(0xFFF7F8F9),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;

            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton(
                onPressed: () => onFilterSelected(filter),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFFDDEDEC)
                      : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0E4C4C)
                        : const Color(0xFFE5E9EB),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? const Color(0xFF0E4C4C)
                        : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
