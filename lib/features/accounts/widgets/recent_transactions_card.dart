import 'package:dafter/features/accounts/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          TransactionTile(
            icon: Icons.arrow_downward_outlined,
            iconBg: Color(0xFFFCEAEA),
            iconColor: Colors.red,
            title: 'دفع للمورد',
            subtitle: 'مورد: شركة النور',
            account: 'الصندوق',
            date: 'اليوم - 10:30 ص',
            amount: '-2,500.00 ريال',
            amountColor: Colors.red,
          ),

          Divider(height: 1, color: Color(0xFFE5E9EB)),

          TransactionTile(
            icon: Icons.arrow_upward_outlined,
            iconBg: Color(0xFFE8F5E9),
            iconColor: Colors.green,
            title: 'قبض من عميل',
            subtitle: 'العميل: أحمد محمد',
            account: 'البنك',
            date: 'اليوم - 09:45 ص',
            amount: '+4,200.00 ريال',
            amountColor: Colors.green,
          ),

          Divider(height: 1, color: Color(0xFFE5E9EB)),

          TransactionTile(
            icon: Icons.compare_arrows_outlined,
            iconBg: Color(0xFFF1F3F4),
            iconColor: Colors.grey,
            title: 'تحويل بين الحسابات',
            subtitle: 'من الصندوق إلى البنك',
            account: 'تحويل',
            date: 'أمس - 04:20 م',
            amount: '3,000.00 ريال',
            amountColor: Color(0xFF333333),
          ),

          Divider(height: 1, color: Color(0xFFE5E9EB)),

          TransactionTile(
            icon: Icons.receipt_long_outlined,
            iconBg: Color(0xFFF3E9DD),
            iconColor: Color(0xFF9C6B30),
            title: 'قيد يومية',
            subtitle: 'تسجيل مصروفات تشغيلية',
            account: 'المصروفات',
            date: 'أمس - 01:15 م',
            amount: '-850.00 ريال',
            amountColor: Colors.red,
          ),

          Divider(height: 1, color: Color(0xFFE5E9EB)),

          TransactionTile(
            icon: Icons.shopping_cart_outlined,
            iconBg: Color(0xFFE8F5E9),
            iconColor: Colors.green,
            title: 'تحصيل مبيعات',
            subtitle: 'فاتورة بيع #1024',
            account: 'الصندوق',
            date: 'أمس - 11:30 ص',
            amount: '+1,750.00 ريال',
            amountColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
