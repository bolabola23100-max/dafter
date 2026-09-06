import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/accounts/screens/add_account_screen.dart';
import 'package:dafter/features/accounts/screens/journal_entry_screen.dart';
import 'package:dafter/features/accounts/screens/payment_receipt_screen.dart';
import 'package:dafter/features/accounts/screens/transfer_screen.dart';
import 'package:dafter/features/accounts/widgets/financial_summary_row.dart';
import 'package:dafter/features/accounts/widgets/recent_transactions_card.dart';
import 'package:flutter/material.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // Action Buttons
          // =========================================================
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.account_balance_outlined,
                  label: 'قيد يومية',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const JournalEntryScreen());
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.add_chart_outlined,
                  label: 'إضافة حساب',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const AddAccountScreen());
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.compare_arrows_outlined,
                  label: 'تحويل',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const TransferScreen());
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'دفع / قبض',
                  primary: true,
                  onTap: () {
                    Nav.push(context, const PaymentReceiptScreen());
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Summary Cards
          // =========================================================
          FinancialSummaryRow(),

          const SizedBox(height: 24),

          // =========================================================
          // Latest Transactions Header
          // =========================================================
          Row(
            children: [
              const Expanded(
                child: Text(
                  'آخر الحركات المالية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              TextButton(
                onPressed: () {
                  // هنربطه بصفحة كل الحركات بعدين
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(child: RecentTransactionsCard()),
        ],
      ),
    );
  }
}
