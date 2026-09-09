import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:flutter/material.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _accountRepository = AccountRepository();
  final _transactionRepository = AccountTransactionRepository();

  List<Account> _accounts = [];
  Account? _fromAccount;
  Account? _toAccount;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountRepository.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        if (accounts.isNotEmpty) _fromAccount = accounts.first;
        if (accounts.length > 1) _toAccount = accounts[1];
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _message('حصلت مشكلة وإحنا بنجيب الحسابات');
      }
    }
  }

  Future<void> _saveTransfer() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_fromAccount == null || _toAccount == null) {
      _message('اختار الحساب اللي هتسحب منه والحساب اللي هتحول له');
      return;
    }
    if (_fromAccount!.id == _toAccount!.id) {
      _message('مينفعش تحول لنفس الحساب');
      return;
    }
    if (amount == null || amount <= 0) {
      _message('اكتب مبلغ صحيح');
      return;
    }

    setState(() => _saving = true);
    try {
      final db = await AppDatabase.instance.database;
      final id = IdGenerator.generate();
      final now = DateTime.now();
      final description = _notesController.text.trim().isEmpty
          ? 'تحويل من ${_fromAccount!.name} إلى ${_toAccount!.name}'
          : _notesController.text.trim();

      await db.transaction((txn) async {
        // Re-read both accounts inside the transaction so a stale screen
        // balance cannot cause an invalid transfer.
        final from = await _accountRepository.getAccountByIdWithExecutor(
          txn,
          _fromAccount!.id,
        );
        final to = await _accountRepository.getAccountByIdWithExecutor(
          txn,
          _toAccount!.id,
        );

        if (from == null || to == null) {
          throw Exception('أحد الحسابات لم يعد موجودًا');
        }
        if (from.id == to.id) {
          throw Exception('مينفعش تحول لنفس الحساب');
        }
        if (from.balance < amount) {
          throw Exception('رصيد الحساب اللي هتسحب منه مش مكفي');
        }

        await _accountRepository.updateBalanceWithExecutor(
          txn,
          from.id,
          from.balance - amount,
        );
        await _accountRepository.updateBalanceWithExecutor(
          txn,
          to.id,
          to.balance + amount,
        );

        await _transactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: IdGenerator.generate(),
            accountId: from.id,
            type: TransactionType.transfer,
            amount: amount,
            isDebit: true,
            date: now,
            referenceId: id,
            description: description,
          ),
        );
        await _transactionRepository.addTransactionWithExecutor(
          txn,
          AccountTransaction(
            id: IdGenerator.generate(),
            accountId: to.id,
            type: TransactionType.transfer,
            amount: amount,
            isDebit: false,
            date: now,
            referenceId: id,
            description: description,
          ),
        );

        await txn.insert(DatabaseTables.transfers, {
          'id': id,
          'from_account_id': from.id,
          'to_account_id': to.id,
          'amount': amount,
          'date': now.toIso8601String(),
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        });
      });

      if (!mounted) return;
      _message('تم التحويل بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message('حصلت مشكلة، التحويل ما اتسجلش: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_accounts.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('تحويل بين الحسابات')),
        body: const Center(child: Text('لازم يكون عندك حسابين على الأقل عشان تعمل تحويل')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('تحويل بين الحسابات'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE5E9EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('تحويل فلوس', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Row(children: [
                    Expanded(child: _accountDropdown('من حساب', _fromAccount, (v) => setState(() => _fromAccount = v))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Icon(Icons.arrow_forward, size: 28)),
                    Expanded(child: _accountDropdown('إلى حساب', _toAccount, (v) => setState(() => _toAccount = v))),
                  ]),
                  const SizedBox(height: 18),
                  CustomTextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'المبلغ', suffixText: 'ج.م', prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات', hintText: 'لو في سبب للتحويل اكتبه هنا', prefixIcon: const Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveTransfer,
                    icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.compare_arrows_outlined),
                    label: Text(_saving ? 'جاري التحويل...' : 'نفّذ التحويل'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountDropdown(String label, Account? value, ValueChanged<Account?> onChanged) {
    return DropdownButtonFormField<Account>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      items: _accounts.map((account) => DropdownMenuItem(value: account, child: Text('${account.name} - ${account.balance.toStringAsFixed(2)} جنيه'))).toList(),
      onChanged: _saving ? null : onChanged,
    );
  }
}
