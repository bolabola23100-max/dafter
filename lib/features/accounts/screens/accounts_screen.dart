import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/screens/account_balances_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _accountRepository.getAccounts();
      final transactions = await _transactionRepository.getTransactions();

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _transactions = transactions;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final accountNames = <String, String>{
      for (final account in _accounts) account.id: account.name,
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'أرصدة المحل',
                  primary: true,
                  onTap: () => _open(const AccountBalancesScreen()),
                ),
              ),
              const SizedBox(width: 12),
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
                  primary: false,
                  onTap: () => _open(const PaymentReceiptScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'آخر الحركات المالية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RecentTransactionsCard(
              transactions: _transactions,
              accountNames: accountNames,
            ),
          ),
        ],
      ),
    );
  }
}
