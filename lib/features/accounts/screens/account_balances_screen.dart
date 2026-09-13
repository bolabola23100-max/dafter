import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/account_transaction.dart';
import 'package:flutter/material.dart';

class AccountBalancesScreen extends StatefulWidget {
  const AccountBalancesScreen({super.key});

  @override
  State<AccountBalancesScreen> createState() => _AccountBalancesScreenState();
}

class _AccountBalancesScreenState extends State<AccountBalancesScreen> {
  final _accountRepository = AccountRepository();
  final _transactionRepository = AccountTransactionRepository();

  bool _loading = true;
  List<Account> _accounts = [];
  Map<String, double> _differences = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final accounts = await _accountRepository.getAccounts();
      final transactions = await _transactionRepository.getTransactions();
      final expected = <String, double>{
        for (final account in accounts) account.id: account.openingBalance,
      };

      for (final transaction in transactions) {
        final current = expected[transaction.accountId];
        if (current == null) continue;
        expected[transaction.accountId] = transaction.isDebit
            ? current - transaction.amount
            : current + transaction.amount;
      }

      final differences = <String, double>{};
      for (final account in accounts) {
        differences[account.id] =
            account.balance - (expected[account.id] ?? account.openingBalance);
      }

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _differences = differences;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أرصدة المحل'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _accounts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('مفيش حسابات مضافة')),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _accounts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _buildAccountCard(_accounts[index]),
                    ),
            ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final difference = _differences[account.id] ?? 0;
    final reconciled = difference.abs() < 0.009;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _money(account.balance),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الرصيد الافتتاحي: ${_money(account.openingBalance)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              reconciled
                  ? '✓ الرصيد مطابق للحركات'
                  : '⚠ فرق مراجعة: ${_money(difference.abs())}',
              style: TextStyle(
                color: reconciled ? Colors.green : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
