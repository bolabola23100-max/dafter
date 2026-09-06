import 'package:dafter/features/model/account_transaction.dart';
import 'package:dafter/features/accounts/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

class RecentTransactionsCard extends StatelessWidget {
  final List<dynamic> transactions;

  const RecentTransactionsCard({super.key, required this.transactions});

  String _title(AccountTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.sale:
        return 'فاتورة بيع';
      case TransactionType.purchase:
        return 'فاتورة شراء';
      case TransactionType.payment:
        return 'دفع';
      case TransactionType.receipt:
        return 'قبض';
      case TransactionType.expense:
        return 'مصروف';
      case TransactionType.transfer:
        return 'تحويل';
      case TransactionType.adjustment:
        return 'تعديل رصيد';
    }
  }

  String _date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E9EB)),
        ),
        alignment: Alignment.center,
        child: const Text('لسه مفيش حركات مالية'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: transactions.length > 10 ? 10 : transactions.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFE5E9EB)),
        itemBuilder: (_, index) {
          final transaction = transactions[index] as AccountTransaction;
          final isDebit = transaction.isDebit;
          return TransactionTile(
            icon: isDebit
                ? Icons.arrow_upward_outlined
                : Icons.arrow_downward_outlined,
            iconBg: isDebit ? const Color(0xFFFCEAEA) : const Color(0xFFE8F5E9),
            iconColor: isDebit ? Colors.red : Colors.green,
            title: transaction.description?.trim().isNotEmpty == true
                ? transaction.description!
                : _title(transaction),
            subtitle: _title(transaction),
            account: transaction.accountId,
            date: _date(transaction.date),
            amount:
                '${isDebit ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} جنيه',
            amountColor: isDebit ? Colors.red : Colors.green,
          );
        },
      ),
    );
  }
}
