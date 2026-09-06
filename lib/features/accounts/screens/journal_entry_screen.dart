import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  String debitAccount = 'الصندوق';
  String creditAccount = 'المبيعات';

  final List<String> accounts = [
    'الصندوق',
    'البنك',
    'المبيعات',
    'المشتريات',
    'الموردين',
    'المصروفات',
    'رأس المال',
  ];

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void saveEntry() {
    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      _message('أدخل مبلغ صحيح');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      _message('أدخل وصف القيد');
      return;
    }

    _message('تم حفظ قيد اليومية بنجاح');
    Navigator.pop(context);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('قيد يومية جديد'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _card(
              title: 'بيانات القيد',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextFormField(
                    openingBalanceController: descriptionController,
                    label: 'وصف القيد',
                    hintText: 'مثال: شراء بضاعة نقدًا',
                    prefixIcon: Icons.description_outlined,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  CustomTextFormField(
                    openingBalanceController: amountController,
                    keyboardType: TextInputType.number,
                    hintText: 'ج.م',
                    label: 'المبلغ',
                    prefixIcon: Icons.payments_outlined,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdown(
                          label: 'الحساب المدين',
                          value: debitAccount,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => debitAccount = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _dropdown(
                          label: 'الحساب الدائن',
                          value: creditAccount,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => creditAccount = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: saveEntry,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ القيد'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
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

  Widget _dropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: accounts
          .map(
            (account) => DropdownMenuItem(value: account, child: Text(account)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
