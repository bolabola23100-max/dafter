import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:flutter/material.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupplierRepository _supplierRepository = SupplierRepository();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final openingBalanceController = TextEditingController();
  final notesController = TextEditingController();

  String balanceType = 'لا يوجد رصيد';
  bool _isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    openingBalanceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> saveSupplier() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    double openingBalance = 0;

    if (balanceType == 'علينا') {
      final value = double.tryParse(
        openingBalanceController.text.trim().replaceAll(',', '.'),
      );

      if (value == null || value < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('من فضلك أدخل مبلغًا صحيحًا'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      openingBalance = value;
    }

    setState(() {
      _isSaving = true;
    });

    final supplier = Supplier(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      phone: _emptyToNull(phoneController.text),
      address: _emptyToNull(addressController.text),
      notes: _emptyToNull(notesController.text),
      openingBalance: openingBalance,
      balance: openingBalance,
    );

    try {
      await _supplierRepository.addSupplier(supplier);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المورد بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ المورد: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'إضافة مورد',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _Card(
                    title: 'بيانات المورد',
                    icon: Icons.store_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                controller: nameController,
                                label: 'اسم المورد',
                                hint: 'مثال: شركة النور',
                                required: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _field(
                                controller: phoneController,
                                label: 'رقم الهاتف',
                                hint: '01xxxxxxxxx',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: addressController,
                          label: 'العنوان',
                          hint: 'عنوان المورد',
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: notesController,
                          label: 'ملاحظات',
                          hint: 'أي ملاحظات إضافية...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'الرصيد الافتتاحي',
                    icon: Icons.account_balance_wallet_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'هل يوجد مبلغ مستحق عند بداية التعامل؟',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 14),
                        RadioGroup<String>(
                          groupValue: balanceType,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                balanceType = value;
                                if (value == 'لا يوجد رصيد') {
                                  openingBalanceController.clear();
                                }
                              });
                            }
                          },
                          child: const Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'لا يوجد رصيد',
                                  title: Text('لا يوجد رصيد'),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  value: 'علينا',
                                  title: Text('علينا للمورد'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (balanceType == 'علينا') ...[
                          const SizedBox(height: 10),
                          _field(
                            controller: openingBalanceController,
                            label: 'المبلغ المستحق',
                            hint: '0.00',
                            suffix: 'ج.م',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final amount = double.tryParse(
                                (value ?? '').trim().replaceAll(',', '.'),
                              );
                              if (amount == null || amount < 0) {
                                return 'أدخل مبلغًا صحيحًا';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : saveSupplier,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ المورد'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return CustomTextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ??
          (required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0E4C4C)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
