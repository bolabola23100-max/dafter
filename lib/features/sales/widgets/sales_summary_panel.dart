import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class SalesSummaryPanel extends StatelessWidget {
  final int itemsCount;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final double paid;
  final double change;
  final TextEditingController discountController;
  final TextEditingController paidController;
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final VoidCallback onSaveAndPrint;
  final VoidCallback onSaveOnly;
  final VoidCallback onValuesChanged;

  const SalesSummaryPanel({
    super.key,
    required this.itemsCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.paid,
    required this.change,
    required this.discountController,
    required this.paidController,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.onSaveAndPrint,
    required this.onSaveOnly,
    required this.onValuesChanged,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryRow('إجمالي العناصر', '$itemsCount'),
          _summaryRow('المجموع الفرعي', '${subtotal.toStringAsFixed(2)} ر.س'),
          const SizedBox(height: 8),
          CustomTextFormField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الخصم',
              isDense: true,
            ),
            onChanged: (_) => onValuesChanged(),
          ),
          const SizedBox(height: 8),
          _summaryRow('الضريبة (15%)', '${tax.toStringAsFixed(2)} ر.س'),
          const Divider(height: 24),
          _summaryRow(
            'الإجمالي النهائي',
            '${grandTotal.toStringAsFixed(2)} ر.س',
            bold: true,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: paidController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المدفوع',
              isDense: true,
            ),
            onChanged: (_) => onValuesChanged(),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            change >= 0 ? 'المتبقي (صرف)' : 'المتبقي على العميل',
            '${change.abs().toStringAsFixed(2)} ر.س',
            color: change >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'طريقة الدفع',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['نقدي', 'بطاقة', 'تحويل', 'آجل'].map((method) {
              final selected = selectedPaymentMethod == method;
              return ChoiceChip(
                label: Text(method),
                selected: selected,
                onSelected: (_) => onPaymentMethodChanged(method),
                selectedColor: const Color(0xFF0E4C4C),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onSaveAndPrint,
            icon: const Icon(Icons.print, size: 18),
            label: const Text('حفظ وطباعة'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onSaveOnly, child: const Text('حفظ فقط')),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 17 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
