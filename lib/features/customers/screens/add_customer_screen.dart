import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/model/customer.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
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
  final _openingBalanceController = TextEditingController(text: '0');
  final _repository = CustomerRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final openingBalance = double.tryParse(
      _openingBalanceController.text.trim().replaceAll(',', ''),
    );
    if (openingBalance == null || openingBalance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب رصيد افتتاحي صحيح')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final customer = Customer(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        openingBalance: openingBalance,
        balance: openingBalance,
      );

      await _repository.addCustomer(customer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتضاف العميل واتحفظ في الجهاز')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حصلت مشكلة في حفظ العميل: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                              border: Border.all(color: const Color(0xFFE5E9EB)),
                            ),
                            child: Column(
                              children: [
                                CustomTextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم العميل *',
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'اكتب اسم العميل'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'رقم التليفون',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'العنوان (اختياري)',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  controller: _openingBalanceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'فلوس عليه من قبل (رصيد افتتاحي)',
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
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveCustomer,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check, size: 19),
                                label: Text(
                                  _isSaving ? 'بيحفظ...' : 'حفظ العميل',
                                ),
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
