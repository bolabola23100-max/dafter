import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إضافة العميل بنجاح')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        body: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E9EB))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 21),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'إضافة عميل جديد',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E9EB),
                              ),
                            ),
                            child: Column(
                              children: [
                                CustomTextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم العميل *',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'هذا الحقل مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم الهاتف',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'العنوان (اختياري)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _saveCustomer,
                                icon: const Icon(Icons.check, size: 19),
                                label: const Text('حفظ العميل'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
