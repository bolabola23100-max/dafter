import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:dafter/features/suppliers/service/supplier_payment_service.dart';
import 'package:flutter/material.dart';

class SupplierPaymentScreen extends StatefulWidget {
  const SupplierPaymentScreen({super.key});

  @override
  State<SupplierPaymentScreen> createState() => _SupplierPaymentScreenState();
}

class _SupplierPaymentScreenState extends State<SupplierPaymentScreen> {
  final _supplierRepository = SupplierRepository();
  final _accountRepository = AccountRepository();
  final _paymentService = SupplierPaymentService();

  final amountController = TextEditingController();
  final notesController = TextEditingController();

  List<Supplier> suppliers = [];
  List<Account> accounts = [];
  String? selectedSupplierId;
  String? selectedAccountId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final loadedSuppliers = await _supplierRepository.getSuppliers();
      final loadedAccounts = await _accountRepository.getAccounts();

      if (!mounted) return;
      setState(() {
        suppliers = loadedSuppliers;
        accounts = loadedAccounts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('حدث خطأ أثناء تحميل البيانات: $e');
    }
  }

  Future<void> savePayment() async {
    if (_isSaving) return;

    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    );

    if (selectedSupplierId == null || selectedAccountId == null) {
      _showMessage('اختر المورد والحساب الذي سيتم الدفع منه');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('أدخل مبلغًا صحيحًا أكبر من صفر');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _paymentService.paySupplier(
        supplierId: selectedSupplierId!,
        accountId: selectedAccountId!,
        amount: amount,
        notes: _emptyToNull(notesController.text),
      );

      if (!mounted) return;
      _showMessage('تم تسجيل الدفعة وتحديث الأرصدة');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'سداد دفعة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E9EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 45,
                          color: Color(0xFF0E4C4C),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'تسجيل دفعة للمورد',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _label('المورد'),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSupplierId,
                          hint: const Text('اختر المورد'),
                          decoration: _decoration(),
                          items: suppliers
                              .map(
                                (supplier) => DropdownMenuItem<String>(
                                  value: supplier.id,
                                  child: Text(
                                    '${supplier.name} — مستحق ${supplier.balance.toStringAsFixed(2)} ج.م',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedSupplierId = value);
                          },
                        ),
                        const SizedBox(height: 18),
                        _label('الحساب الذي سيتم الدفع منه'),
                        DropdownButtonFormField<String>(
                          initialValue: selectedAccountId,
                          hint: const Text('اختر الحساب'),
                          decoration: _decoration(),
                          items: accounts
                              .map(
                                (account) => DropdownMenuItem<String>(
                                  value: account.id,
                                  child: Text(
                                    '${account.name} — الرصيد ${account.balance.toStringAsFixed(2)} ج.م',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedAccountId = value);
                          },
                        ),
                        const SizedBox(height: 18),
                        _label('المبلغ'),
                        CustomTextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _decoration(
                            hint: '0.00',
                            suffix: 'ج.م',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _label('ملاحظات'),
                        CustomTextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: _decoration(hint: 'ملاحظات الدفعة...'),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : savePayment,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              _isSaving ? 'جارٍ التسجيل...' : 'تسجيل الدفعة',
                            ),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _decoration({String? hint, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    );
  }
}
