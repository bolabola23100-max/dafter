import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/expenses/repo/expense_repository.dart';
import 'package:dafter/features/expenses/service/expense_service.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/expense.dart';
import 'package:flutter/material.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseRepository _repository = ExpenseRepository();
  final ExpenseService _service = ExpenseService();
  final AccountRepository _accountRepository = AccountRepository();

  List<Expense> _expenses = [];
  List<Account> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repository.getExpenses(),
        _accountRepository.getAccounts(),
      ]);
      if (!mounted) return;
      setState(() {
        _expenses = results[0] as List<Expense>;
        _accounts = results[1] as List<Account>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('حصلت مشكلة وإحنا بنجيب المصروفات');
    }
  }

  Future<void> _addExpense() async {
    if (_accounts.isEmpty) {
      _message('ضيف حساب الأول عشان تسجل مصروف');
      return;
    }

    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    Account selectedAccount = _accounts.first;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل مصروف'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'المصروف على إيه؟',
                      hintText: 'مثال: إيجار، كهربا، نقل',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'المبلغ بالجنيه'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Account>(
                    initialValue: selectedAccount,
                    decoration: const InputDecoration(labelText: 'الحساب اللي هيتخصم منه'),
                    items: _accounts.map((account) => DropdownMenuItem(
                      value: account,
                      child: Text(account.name),
                    )).toList(),
                    onChanged: saving ? null : (value) {
                      if (value != null) setDialogState(() => selectedAccount = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                final amount = double.tryParse(amountController.text.trim());
                if (categoryController.text.trim().isEmpty || amount == null || amount <= 0) {
                  _message('اكتب نوع المصروف والمبلغ صح');
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  await _service.createExpense(
                    Expense(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      accountId: selectedAccount.id,
                      category: categoryController.text.trim(),
                      amount: amount,
                      date: DateTime.now(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    ),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) setDialogState(() => saving = false);
                  _message(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    categoryController.dispose();
    amountController.dispose();
    notesController.dispose();
    if (saved == true) await _load();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    final total = _expenses.fold<double>(0, (sum, item) => sum + item.amount);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المصروفات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('سجل كل الفلوس اللي بتطلع من المحل', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _addExpense,
                icon: const Icon(Icons.add),
                label: const Text('مصروف جديد'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.money_off_outlined, size: 30),
                  const SizedBox(width: 14),
                  const Text('إجمالي المصروفات المسجلة', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(_money(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? const Center(child: Text('لسه مفيش مصروفات مسجلة'))
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _expenses.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            final account = _accounts.where((a) => a.id == expense.accountId).firstOrNull;
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.money_off_outlined)),
                              title: Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${account?.name ?? 'حساب محذوف'} • ${expense.date.day}/${expense.date.month}/${expense.date.year}'),
                              trailing: Text(_money(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
