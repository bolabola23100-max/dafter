import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/accounts/repo/account_transaction_repository.dart';
import 'package:dafter/features/accounts/screens/add_account_screen.dart';
import 'package:dafter/features/accounts/screens/journal_entry_screen.dart';
import 'package:dafter/features/accounts/screens/payment_receipt_screen.dart';
import 'package:dafter/features/accounts/screens/transfer_screen.dart';
import 'package:dafter/features/accounts/widgets/financial_summary_row.dart';
import 'package:dafter/features/accounts/widgets/recent_transactions_card.dart';
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
  List<dynamic> _transactions = [];
  double _balance = 0;
  double _receipts = 0;
  double _payments = 0;

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
        _balance = accounts.fold(0, (sum, item) => sum + item.balance);
        _receipts = transactions.where((item) => !item.isDebit).fold(0, (sum, item) => sum + item.amount);
        _payments = transactions.where((item) => item.isDebit).fold(0, (sum, item) => sum + item.amount);
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: ActionButton(icon: Icons.account_balance_outlined, label: 'قيد يومية', primary: false, onTap: () => _open(const JournalEntryScreen()))),
            const SizedBox(width: 12),
            Expanded(child: ActionButton(icon: Icons.add_chart_outlined, label: 'إضافة حساب', primary: false, onTap: () => _open(const AddAccountScreen()))),
            const SizedBox(width: 12),
            Expanded(child: ActionButton(icon: Icons.compare_arrows_outlined, label: 'تحويل', primary: false, onTap: () => _open(const TransferScreen()))),
            const SizedBox(width: 12),
            Expanded(child: ActionButton(icon: Icons.payments_outlined, label: 'دفع / قبض', primary: true, onTap: () => _open(const PaymentReceiptScreen()))),
          ]),
          const SizedBox(height: 20),
          FinancialSummaryRow(totalBalance: _balance, totalReceipts: _receipts, totalPayments: _payments),
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Text('آخر الحركات المالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            TextButton(onPressed: () {}, child: const Text('عرض الكل')),
          ]),
          const SizedBox(height: 12),
          Expanded(child: RecentTransactionsCard(transactions: _transactions)),
        ],
      ),
    );
  }
}
