import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/service/account_operation_service.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:flutter/material.dart';

class PaymentReceiptScreen extends StatefulWidget {
  const PaymentReceiptScreen({super.key});

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  final personController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final _accountRepository = AccountRepository();
  final _operationService = AccountOperationService();

  String operation = 'قبض';
  Account? selectedAccount;
  List<Account> accounts = [];
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final result = await _accountRepository.getAccounts();
      if (!mounted) return;
      setState(() {
        accounts = result;
        selectedAccount = result.isEmpty ? null : result.first;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _message('مقدرناش نحمل الحسابات: $e');
      }
    }
  }

  @override
  void dispose() {
    personController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> saveOperation() async {
    if (saving) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      _message('اكتب مبلغ صحيح');
      return;
    }
    if (selectedAccount == null) {
      _message('ضيف حساب الأول علشان تسجل العملية');
      return;
    }

    setState(() => saving = true);
    try {
      await _operationService.savePaymentOrReceipt(
        type: operation == 'قبض' ? PaymentType.receipt : PaymentType.payment,
        accountId: selectedAccount!.id,
        amount: amount,
        personName: personController.text.trim(),
        notes: notesController.text.trim(),
      );
      if (!mounted) return;
      _message(operation == 'قبض' ? 'اتسجل القبض' : 'اتسجل الدفع');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message('مقدرناش نسجل العملية: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt = operation == 'قبض';
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(title: const Text('دفع / قبض'), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE5E9EB))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('عملية مالية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: _operationButton('قبض', Icons.arrow_downward, isReceipt, () => setState(() => operation = 'قبض'))),
                  const SizedBox(width: 12),
                  Expanded(child: _operationButton('دفع', Icons.arrow_upward, !isReceipt, () => setState(() => operation = 'دفع'))),
                ]),
                const SizedBox(height: 20),
                CustomTextFormField(controller: personController, decoration: InputDecoration(labelText: isReceipt ? 'من' : 'إلى', hintText: 'اسم الشخص أو الجهة', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccount?.id,
                  decoration: InputDecoration(labelText: 'الحساب', prefixIcon: const Icon(Icons.account_balance_wallet_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} — ${a.balance.toStringAsFixed(2)} جنيه'))).toList(),
                  onChanged: saving ? null : (id) => setState(() => selectedAccount = accounts.firstWhere((a) => a.id == id)),
                ),
                const SizedBox(height: 16),
                CustomTextFormField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'المبلغ', suffixText: 'ج.م', prefixIcon: const Icon(Icons.payments_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                CustomTextFormField(controller: notesController, maxLines: 3, decoration: InputDecoration(labelText: 'ملاحظات', prefixIcon: const Icon(Icons.notes_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 25),
                ElevatedButton.icon(onPressed: saving ? null : saveOperation, icon: Icon(isReceipt ? Icons.arrow_downward : Icons.arrow_upward), label: Text(isReceipt ? 'تسجيل القبض' : 'تسجيل الدفع'), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _operationButton(String title, IconData icon, bool selected, VoidCallback onTap) {
    return OutlinedButton.icon(onPressed: saving ? null : onTap, icon: Icon(icon), label: Text(title), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), side: BorderSide(color: selected ? const Color(0xFF0E4C4C) : const Color(0xFFE5E9EB), width: selected ? 2 : 1)));
  }
}
