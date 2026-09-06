import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/customer.dart';
import 'package:dafter/features/customers/service/customer_payment_service.dart';
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
  final _notesController = TextEditingController();
  final _accountRepository = AccountRepository();
  final _paymentService = CustomerPaymentService();
  Customer? selectedCustomer;
  Account? selectedAccount;
  List<Account> accounts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customers.length == 1) selectedCustomer = widget.customers.first;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final result = await _accountRepository.getAccounts();
      if (!mounted) return;
      setState(() {
        accounts = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('مش قادر أجيب الحسابات: $e')));
    }
  }

  Future<void> _savePayment() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (selectedCustomer == null) {
      _msg('اختار العميل الأول');
      return;
    }
    if (selectedAccount == null) {
      _msg('اختار الحساب اللي هتدخل فيه الفلوس');
      return;
    }
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) {
      _msg('اكتب مبلغ صحيح');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _paymentService.receivePayment(
        customerId: selectedCustomer!.id,
        accountId: selectedAccount!.id,
        amount: amount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      _msg('اتسجل التحصيل واتحفظ في الحساب');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
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
                    'تحصيل دفعة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
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
                                        hint: const Text('اختار العميل'),
                                        items: widget.customers
                                            .map(
                                              (c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(
                                                  '${c.name} — عليه ${c.balance.toStringAsFixed(2)} جنيه',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: _isSaving
                                            ? null
                                            : (value) => setState(
                                                () => selectedCustomer = value,
                                              ),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<Account>(
                                        initialValue: selectedAccount,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'الحساب اللي هتدخل فيه الفلوس *',
                                        ),
                                        hint: const Text('اختار الحساب'),
                                        items: accounts
                                            .map(
                                              (a) => DropdownMenuItem(
                                                value: a,
                                                child: Text(
                                                  '${a.name} — ${a.balance.toStringAsFixed(2)} جنيه',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: _isSaving
                                            ? null
                                            : (value) => setState(
                                                () => selectedAccount = value,
                                              ),
                                      ),
                                      const SizedBox(height: 16),
                                      CustomTextFormField(
                                        controller: _amountController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'المبلغ *',
                                          suffixText: 'جنيه',
                                        ),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                            ? 'اكتب المبلغ'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      CustomTextFormField(
                                        controller: _notesController,
                                        decoration: const InputDecoration(
                                          labelText: 'ملاحظات (اختياري)',
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
                                      onPressed: _isSaving
                                          ? null
                                          : _savePayment,
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
                                        _isSaving
                                            ? 'بيحفظ...'
                                            : 'تسجيل التحصيل',
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
