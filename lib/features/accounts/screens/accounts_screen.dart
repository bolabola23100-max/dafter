import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/screens/add_account_screen.dart';
import 'package:dafter/features/accounts/screens/journal_entry_screen.dart';
import 'package:dafter/features/accounts/screens/payment_receipt_screen.dart';
import 'package:dafter/features/accounts/screens/transfer_screen.dart';
import 'package:dafter/features/accounts/widgets/recent_transactions_card.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:flutter/material.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _accountRepository = AccountRepository();
  final _transactionRepository = AccountTransactionRepository();

  bool _loading = true;
  List<Account> _accounts = [];
  List<AccountTransaction> _transactions = [];
  double _balance = 0;
  double _receipts = 0;
  double _payments = 0;
  Map<String, double> _reconciliationDifferences = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _accountRepository.getAccounts();
      final transactions = await _transactionRepository.getTransactions();
      final expectedBalances = <String, double>{
        for (final account in accounts) account.id: account.openingBalance,
      };

      var receipts = 0.0;
      var payments = 0.0;
      for (final transaction in transactions) {
        final current = expectedBalances[transaction.accountId];
        if (current == null) continue;
        expectedBalances[transaction.accountId] = transaction.isDebit
            ? current - transaction.amount
            : current + transaction.amount;
        if (transaction.isDebit) {
          payments += transaction.amount;
        } else {
          receipts += transaction.amount;
        }
      }

      final differences = <String, double>{};
      for (final account in accounts) {
        final expected = expectedBalances[account.id] ?? account.openingBalance;
        differences[account.id] = account.balance - expected;
      }

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _transactions = transactions;
        _balance = accounts.fold(0.0, (sum, item) => sum + item.balance);
        _receipts = receipts;
        _payments = payments;
        _reconciliationDifferences = differences;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Widget page) async {
    await Nav.push(context, page);
    await _loadData();
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.account_balance_outlined,
                  label: 'قيد يومية',
                  primary: false,
                  onTap: () => _open(const JournalEntryScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.add_chart_outlined,
                  label: 'إضافة حساب',
                  primary: false,
                  onTap: () => _open(const AddAccountScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.compare_arrows_outlined,
                  label: 'تحويل',
                  primary: false,
                  onTap: () => _open(const TransferScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'دفع / قبض',
                  primary: true,
                  onTap: () => _open(const PaymentReceiptScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(),
          const SizedBox(height: 20),
          const Text(
            'أرصدة المحل',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: _accounts.isEmpty
                ? const Center(child: Text('مفيش حسابات مضافة'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, index) => _buildAccountCard(_accounts[index]),
                  ),
          ),
          const SizedBox(height: 20),
          const Text(
            'آخر الحركات المالية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(child: RecentTransactionsCard(transactions: _transactions, accountNames: _accounts.map((a) => MapEntry(a.id, a.name)).fold<Map<String, String>>({}, (map, entry) { map[entry.key] = entry.value; return map; }))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(child: _summaryCard(Icons.account_balance_wallet_outlined, 'الرصيد الكلي', _money(_balance))),
        const SizedBox(width: 16),
        Expanded(child: _summaryCard(Icons.arrow_downward_outlined, 'إجمالي القبض', _money(_receipts))),
        const SizedBox(width: 16),
        Expanded(child: _summaryCard(Icons.arrow_upward_outlined, 'إجمالي الدفع', _money(_payments))),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final difference = _reconciliationDifferences[account.id] ?? 0;
    final reconciled = difference.abs() < 0.009;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reconciled ? const Color(0xFFE5E9EB) : Colors.orange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _money(account.balance),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            reconciled
                ? '✓ الرصيد مطابق للحركات'
                : '⚠ فرق مراجعة: ${_money(difference.abs())}',
            style: TextStyle(
              fontSize: 12,
              color: reconciled ? Colors.green : Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
