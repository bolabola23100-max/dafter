import 'package:flutter/material.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceNumberController = TextEditingController();
  final _returnAmountController = TextEditingController();

  String? selectedReason;

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _returnAmountController.dispose();
    super.dispose();
  }

  void _confirmReturn() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تسجيل المرتجع بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInvoiceCard(),
                          const SizedBox(height: 16),
                          _buildReturnDetailsCard(),
                          const SizedBox(height: 16),
                          _buildBottomActions(),
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

  Widget _buildHeader() {
    return Container(
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
            'مرتجع مبيعات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard() {
    return _SectionCard(
      title: 'الفاتورة الأصلية',
      icon: Icons.search,
      child: _buildCustomTextFormField(
        controller: _invoiceNumberController,
        label: 'رقم الفاتورة',
        hint: 'ابحث برقم الفاتورة',
        required: true,
      ),
    );
  }

  Widget _buildReturnDetailsCard() {
    return _SectionCard(
      title: 'تفاصيل المرتجع',
      icon: Icons.assignment_return_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildCustomTextFormField(
              controller: _returnAmountController,
              label: 'إجمالي قيمة المرتجع',
              hint: '0.00',
              suffix: 'ج.م',
              keyboardType: TextInputType.number,
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDropdown(
              label: 'سبب الإرجاع',
              value: selectedReason,
              hint: 'اختر السبب',
              items: const ['تالف', 'خطأ في الطلب', 'لا يعمل', 'أخرى'],
              onChanged: (value) => setState(() => selectedReason = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          child: const Text('إلغاء'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _confirmReturn,
          icon: const Icon(Icons.check, size: 19),
          label: const Text('تأكيد المرتجع'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF0E4C4C), width: 1.5),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFE5E9EB)),
        ),
      ),
      hint: Text(hint),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

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
              Icon(icon, size: 19, color: const Color(0xFF0E4C4C)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
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
