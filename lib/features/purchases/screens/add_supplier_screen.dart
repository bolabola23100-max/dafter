import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void saveSupplier() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة المورد بنجاح'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('إضافة مورد'),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E9EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'بيانات المورد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _field(
                      controller: nameController,
                      label: 'اسم المورد',
                      hint: 'مثال: شركة النور',
                      icon: Icons.person_outline,
                      requiredField: true,
                    ),

                    const SizedBox(height: 16),

                    _field(
                      controller: phoneController,
                      label: 'رقم الهاتف',
                      hint: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 16),

                    _field(
                      controller: addressController,
                      label: 'العنوان',
                      hint: 'عنوان المورد',
                      icon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 16),

                    _field(
                      controller: notesController,
                      label: 'ملاحظات',
                      hint: 'أي ملاحظات إضافية',
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: saveSupplier,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('حفظ المورد'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
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
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = false,
    int maxLines = 1,
  }) {
    return CustomTextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'من فضلك أدخل $label';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
      ),
    );
  }
}
