import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class PaymentReceiptScreen extends StatefulWidget {
  const PaymentReceiptScreen({super.key});

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  final personController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  String operation = 'قبض';
  String account = 'الصندوق';

  final accounts = ['الصندوق', 'البنك', 'خزنة المحل'];

  @override
  void dispose() {
    personController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void saveOperation() {
    final amount = double.tryParse(amountController.text);

    if (personController.text.trim().isEmpty) {
      _message(
        operation == 'قبض'
            ? 'أدخل اسم الشخص أو الجهة التي دفعت'
            : 'أدخل اسم الشخص أو الجهة التي تم الدفع لها',
      );
      return;
    }

    if (amount == null || amount <= 0) {
      _message('أدخل مبلغ صحيح');
      return;
    }

    _message(
      operation == 'قبض' ? 'تم تسجيل عملية القبض' : 'تم تسجيل عملية الدفع',
    );

    Navigator.pop(context);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt = operation == 'قبض';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('دفع / قبض'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E9EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'عملية مالية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: _operationButton(
                          title: 'قبض',
                          icon: Icons.arrow_downward,
                          selected: isReceipt,
                          onTap: () {
                            setState(() {
                              operation = 'قبض';
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _operationButton(
                          title: 'دفع',
                          icon: Icons.arrow_upward,
                          selected: !isReceipt,
                          onTap: () {
                            setState(() {
                              operation = 'دفع';
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  CustomTextFormField(
                    controller: personController,
                    decoration: InputDecoration(
                      labelText: isReceipt ? 'من' : 'إلى',
                      hintText: 'اسم الشخص أو الجهة',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: account,
                    decoration: InputDecoration(
                      labelText: 'الحساب',
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: accounts
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => account = value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      suffixText: 'ج.م',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  CustomTextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'البيان / ملاحظات',
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: saveOperation,
                    icon: Icon(
                      isReceipt ? Icons.arrow_downward : Icons.arrow_upward,
                    ),
                    label: Text(isReceipt ? 'تسجيل القبض' : 'تسجيل الدفع'),
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

  Widget _operationButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(
          color: selected ? const Color(0xFF0E4C4C) : const Color(0xFFE5E9EB),
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}
