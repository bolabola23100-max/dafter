import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/service/journal_entry_service.dart';
import 'package:dafter/features/model/account.dart';
import 'package:flutter/material.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final AccountRepository _accountRepository = AccountRepository();
  final JournalEntryService _journalEntryService = JournalEntryService();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  List<Account> accounts = [];
  Account? debitAccount;
  Account? creditAccount;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final result = await _accountRepository.getAccounts();
      if (!mounted) return;
      setState(() {
        accounts = result;
        if (accounts.isNotEmpty) debitAccount = accounts.first;
        if (accounts.length > 1) creditAccount = accounts[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _message('حصلت مشكلة وأنا بجيب الحسابات');
    }
  }

  Future<void> saveEntry() async {
    if (_isSaving) return;
    if (accounts.length < 2) {
      _message('لازم يكون عندك حسابين على الأقل');
      return;
    }
    if (debitAccount == null || creditAccount == null) {
      _message('اختار الحسابين الأول');
      return;
    }
    if (debitAccount!.id == creditAccount!.id) {
      _message('مينفعش تختار نفس الحساب في الطرفين');
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      _message('اكتب مبلغ صحيح');
      return;
    }

    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      _message('اكتب وصف القيد');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _journalEntryService.saveEntry(
        debitAccountId: debitAccount!.id,
        creditAccountId: creditAccount!.id,
        amount: amount,
        description: description,
      );
      if (!mounted) return;
      _message('القيد اتحفظ واتحدثت أرصدة الحسابات');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('قيد يومية جديد'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : accounts.length < 2
              ? _emptyAccounts()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _card(
                        title: 'بيانات القيد',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextFormField(
                              openingBalanceController: descriptionController,
                              label: 'وصف القيد',
                              hintText: 'مثال: شراء بضاعة نقدًا',
                              prefixIcon: Icons.description_outlined,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextFormField(
                              openingBalanceController: amountController,
                              keyboardType: TextInputType.number,
                              hintText: 'جنيه',
                              label: 'المبلغ',
                              prefixIcon: Icons.payments_outlined,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _dropdown(
                                    label: 'الحساب اللي هيدخل له الفلوس',
                                    value: debitAccount,
                                    onChanged: (value) => setState(() => debitAccount = value),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _dropdown(
                                    label: 'الحساب اللي هتطلع منه الفلوس',
                                    value: creditAccount,
                                    onChanged: (value) => setState(() => creditAccount = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : saveEntry,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_isSaving ? 'بيحفظ...' : 'حفظ القيد'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
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

  Widget _dropdown({
    required String label,
    required Account? value,
    required ValueChanged<Account?> onChanged,
  }) {
    return DropdownButtonFormField<Account>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: accounts
          .map((account) => DropdownMenuItem<Account>(
                value: account,
                child: Text(account.name),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _emptyAccounts() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _card(
          title: 'مفيش حسابات كفاية',
          child: Column(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 55),
              const SizedBox(height: 16),
              const Text(
                'لازم تعمل حسابين على الأقل عشان تعمل قيد يومية.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
