import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  String fromAccount = 'الصندوق';
  String toAccount = 'البنك';

  final accounts = ['الصندوق', 'البنك', 'خزنة المحل', 'حساب آخر'];

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void saveTransfer() {
    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      _message('أدخل مبلغ صحيح');
      return;
    }

    if (fromAccount == toAccount) {
      _message('لا يمكن التحويل لنفس الحساب');
      return;
    }

    _message('تم تسجيل التحويل بنجاح');
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
        title: const Text('تحويل بين الحسابات'),
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
                    'تحويل أموال',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: _accountDropdown(
                          label: 'من حساب',
                          value: fromAccount,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => fromAccount = value);
                            }
                          },
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Icon(Icons.arrow_forward, size: 28),
                      ),

                      Expanded(
                        child: _accountDropdown(
                          label: 'إلى حساب',
                          value: toAccount,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => toAccount = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

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
                      labelText: 'ملاحظات',
                      hintText: 'سبب التحويل...',
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: saveTransfer,
                    icon: const Icon(Icons.compare_arrows_outlined),
                    label: const Text('تنفيذ التحويل'),
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

  Widget _accountDropdown({
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
}
