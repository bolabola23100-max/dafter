import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class SupplierPaymentScreen extends StatefulWidget {
  const SupplierPaymentScreen({super.key});

  @override
  State<SupplierPaymentScreen> createState() => _SupplierPaymentScreenState();
}

class _SupplierPaymentScreenState extends State<SupplierPaymentScreen> {
  String? selectedSupplier;
  String paymentMethod = 'نقدي';

  final amountController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void savePayment() {
    if (selectedSupplier == null || amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر المورد وأدخل المبلغ'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تسجيل الدفعة بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'سداد دفعة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E9EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 45,
                    color: Color(0xFF0E4C4C),
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'تسجيل دفعة للمورد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _label('المورد'),

                  DropdownButtonFormField<String>(
                    initialValue: selectedSupplier,
                    hint: const Text('اختر المورد'),
                    decoration: _decoration(),
                    items:
                        const [
                              'شركة النور',
                              'أحمد للإكسسوارات',
                              'مؤسسة الأمل',
                              'مورد الإكسسوارات',
                            ]
                            .map(
                              (supplier) => DropdownMenuItem(
                                value: supplier,
                                child: Text(supplier),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSupplier = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  _label('المبلغ'),

                  CustomTextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration(hint: '0.00', suffix: 'ج.م'),
                  ),

                  const SizedBox(height: 18),

                  _label('طريقة الدفع'),

                  Row(
                    children: [
                      _paymentOption('نقدي', Icons.money),
                      _paymentOption('تحويل بنكي', Icons.account_balance),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _label('ملاحظات'),

                  CustomTextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: _decoration(hint: 'ملاحظات الدفعة...'),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: savePayment,
                      icon: const Icon(Icons.check),
                      label: const Text('تسجيل الدفعة'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(String title, IconData icon) {
    final selected = paymentMethod == title;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            paymentMethod = title;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDEDEC) : Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0E4C4C)
                  : const Color(0xFFE5E9EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 7),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _decoration({String? hint, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    );
  }
}
