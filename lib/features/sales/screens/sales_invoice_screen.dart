import 'package:flutter/material.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _totalController = TextEditingController();
  final _paidController = TextEditingController();

  String? selectedCustomer;
  String? selectedPaymentMethod;

  @override
  void dispose() {
    _totalController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _saveInvoice() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ فاتورة البيع بنجاح')));
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
                          _buildCustomerCard(),
                          const SizedBox(height: 16),
                          _buildPaymentCard(),
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
            'فاتورة بيع جديدة',
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

  Widget _buildCustomerCard() {
    return _SectionCard(
      title: 'بيانات العميل',
      icon: Icons.person_outline,
      child: _buildDropdown(
        label: 'العميل',
        value: selectedCustomer,
        hint: 'اختر العميل أو اتركه كعميل نقدي',
        items: const ['عميل نقدي', 'مؤسسة الأفق للتجارة', 'شركة النور'],
        onChanged: (value) => setState(() => selectedCustomer = value),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return _SectionCard(
      title: 'الدفع',
      icon: Icons.payments_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildCustomTextFormField(
              controller: _totalController,
              label: 'الإجمالي',
              hint: '0.00',
              suffix: 'ج.م',
              keyboardType: TextInputType.number,
              required: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCustomTextFormField(
              controller: _paidController,
              label: 'المدفوع',
              hint: '0.00',
              suffix: 'ج.م',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDropdown(
              label: 'طريقة الدفع',
              value: selectedPaymentMethod,
              hint: 'اختر الطريقة',
              items: const ['نقدي', 'بطاقة', 'تحويل', 'آجل'],
              onChanged: (value) =>
                  setState(() => selectedPaymentMethod = value),
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
          onPressed: _saveInvoice,
          icon: const Icon(Icons.check, size: 19),
          label: const Text('حفظ وطباعة'),
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
