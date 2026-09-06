import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final nameController = TextEditingController();
  final openingBalanceController = TextEditingController();
  final noteController = TextEditingController();
  String type = 'صندوق';

  final types = ['صندوق', 'بنك', 'مصروف', 'إيراد', 'أخرى'];

  @override
  void dispose() {
    nameController.dispose();
    openingBalanceController.dispose();
    super.dispose();
  }

  void saveAccount() {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      _message('أدخل اسم الحساب');
      return;
    }

    final balance = double.tryParse(openingBalanceController.text) ?? 0;

    if (balance < 0) {
      _message('الرصيد الافتتاحي غير صحيح');
      return;
    }

    _message('تم إضافة الحساب بنجاح');
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
        title: const Text('إضافة حساب'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
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
                    'حساب جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 22),

                  CustomTextFormField(
                    openingBalanceController: nameController,
                    label: 'اسم الحساب',
                    hintText: 'مثال: خزنة المحل',
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: 'نوع الحساب',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: types
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => type = value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextFormField(
                    openingBalanceController: openingBalanceController,
                    label: 'الرصيد الافتتاحي',
                    hintText: '0.00',
                    suffixText: 'ج.م',
                    prefixIcon: Icons.money_outlined,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: saveAccount,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ الحساب'),
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
}
