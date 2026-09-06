import 'package:dafter/features/reports/widgets/report_row.dart';
import 'package:flutter/material.dart';

class ReportsTable extends StatelessWidget {
  final int salesCount;
  final double salesTotal;
  final int purchasesCount;
  final double purchasesTotal;
  final int expensesCount;
  final double expensesTotal;
  final int salesReturnsCount;
  final double salesReturnsTotal;
  final int purchaseReturnsCount;
  final double purchaseReturnsTotal;
  final double stockValue;

  const ReportsTable({
    super.key,
    required this.salesCount,
    required this.salesTotal,
    required this.purchasesCount,
    required this.purchasesTotal,
    required this.expensesCount,
    required this.expensesTotal,
    required this.salesReturnsCount,
    required this.salesReturnsTotal,
    required this.purchaseReturnsCount,
    required this.purchaseReturnsTotal,
    required this.stockValue,
  });

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    final rows = [
      ReportRow(
        icon: Icons.shopping_cart_outlined,
        title: 'المبيعات',
        subtitle: 'إجمالي فواتير البيع',
        operations: '$salesCount',
        amount: _money(salesTotal),
        status: 'محدث',
      ),
      ReportRow(
        icon: Icons.shopping_bag_outlined,
        title: 'المشتريات',
        subtitle: 'إجمالي فواتير الشراء',
        operations: '$purchasesCount',
        amount: _money(purchasesTotal),
        status: 'محدث',
      ),
      ReportRow(
        icon: Icons.money_off_outlined,
        title: 'المصروفات',
        subtitle: 'المصروفات المسجلة',
        operations: '$expensesCount',
        amount: _money(expensesTotal),
        status: 'محدث',
      ),
      ReportRow(
        icon: Icons.assignment_return_outlined,
        title: 'مرتجعات البيع',
        subtitle: 'الفواتير اللي رجعت من العملاء',
        operations: '$salesReturnsCount',
        amount: _money(salesReturnsTotal),
        status: 'محدث',
      ),
      ReportRow(
        icon: Icons.keyboard_return_outlined,
        title: 'مرتجعات الشراء',
        subtitle: 'البضاعة اللي رجعت للموردين',
        operations: '$purchaseReturnsCount',
        amount: _money(purchaseReturnsTotal),
        status: 'محدث',
      ),
      ReportRow(
        icon: Icons.inventory_2_outlined,
        title: 'المخزون',
        subtitle: 'قيمة المخزون بسعر الشراء الحالي',
        operations: '-',
        amount: _money(stockValue),
        status: 'محدث',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('التقرير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(child: Text('عدد العمليات', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(child: Text('القيمة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(child: Text('الحالة', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: ListView(children: rows)),
        ],
      ),
    );
  }
}
