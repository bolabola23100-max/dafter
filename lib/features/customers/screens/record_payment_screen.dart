import 'package:dafter/features/customers/model/customer.dart';
import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class RecordPaymentScreen extends StatefulWidget {
  final List<Customer> customers;
  const RecordPaymentScreen({super.key, required this.customers});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Customer? selectedCustomer;
  String paymentMethod = 'نقدي';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _savePayment() {
    if (!_formKey.currentState!.validate() || selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر العميل أولًا')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة بنجاح')));
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
                    'تحصيل دفعة',
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
                                DropdownButtonFormField<Customer>(
                                  initialValue: selectedCustomer,
                                  decoration: const InputDecoration(
                                    labelText: 'العميل *',
                                  ),
                                  hint: const Text('اختر العميل'),
                                  items: widget.customers.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.name} (متبقي ${c.remaining.toStringAsFixed(2)} ر.س)',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      setState(() => selectedCustomer = value),
                                ),
                                const SizedBox(height: 16),
                                CustomTextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'المبلغ *',
                                    suffixText: 'ر.س',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'هذا الحقل مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: paymentMethod,
                                  decoration: const InputDecoration(
                                    labelText: 'طريقة الدفع',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'نقدي',
                                      child: Text('نقدي'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'بطاقة',
                                      child: Text('بطاقة'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'تحويل',
                                      child: Text('تحويل'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => paymentMethod = value!),
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
                                onPressed: _savePayment,
                                icon: const Icon(Icons.check, size: 19),
                                label: const Text('تسجيل الدفعة'),
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
