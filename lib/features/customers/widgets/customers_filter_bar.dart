import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class CustomersFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool showDebtorsOnly;
  final ValueChanged<bool> onDebtorsFilterChanged;
  final ValueChanged<String> onSearchChanged;

  const CustomersFilterBar({
    super.key,
    required this.searchController,
    required this.showDebtorsOnly,
    required this.onDebtorsFilterChanged,
    required this.onSearchChanged,
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
            flex: 2,
            child: CustomTextFormField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'البحث بالاسم أو الهاتف...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('المدينون فقط'),
            selected: showDebtorsOnly,
            onSelected: onDebtorsFilterChanged,
            selectedColor: const Color(0xFF0E4C4C).withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}
