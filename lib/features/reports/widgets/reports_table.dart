import 'package:dafter/features/reports/widgets/report_row.dart';
import 'package:flutter/material.dart';

class ReportsTable extends StatelessWidget {
  const ReportsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'التقرير',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'عدد العمليات',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'القيمة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الحالة',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Table Rows
          Expanded(
            child: ListView(
              children: const [
                ReportRow(
                  icon: Icons.shopping_cart_outlined,
                  title: 'المبيعات',
                  subtitle: 'إجمالي فواتير البيع',
                  operations: '84',
                  amount: '62,500.00 ريال',
                  status: 'مكتمل',
                ),
                ReportRow(
                  icon: Icons.shopping_bag_outlined,
                  title: 'المشتريات',
                  subtitle: 'إجمالي فواتير الشراء',
                  operations: '36',
                  amount: '31,200.00 ريال',
                  status: 'مكتمل',
                ),
                ReportRow(
                  icon: Icons.money_off_outlined,
                  title: 'المصروفات',
                  subtitle: 'المصروفات التشغيلية',
                  operations: '22',
                  amount: '8,450.00 ريال',
                  status: 'مكتمل',
                ),
                ReportRow(
                  icon: Icons.inventory_2_outlined,
                  title: 'المخزون',
                  subtitle: 'قيمة المخزون الحالية',
                  operations: '428',
                  amount: '115,800.00 ريال',
                  status: 'محدث',
                ),
                ReportRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'الأرباح',
                  subtitle: 'صافي الأرباح',
                  operations: '84',
                  amount: '44,550.00 ريال',
                  status: 'مكتمل',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
