import 'package:dafter/features/reports/model/report_summary.dart';
import 'package:dafter/features/reports/service/report_service.dart';
import 'package:flutter/material.dart';

class FullReportScreen extends StatefulWidget {
  const FullReportScreen({super.key});

  @override
  State<FullReportScreen> createState() => _FullReportScreenState();
}

class _FullReportScreenState extends State<FullReportScreen> {
  final ReportService _service = ReportService();
  late Future<ReportSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSummary();
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقرير الشامل')),
      body: FutureBuilder<ReportSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('حصلت مشكلة وإحنا بنجيب التقرير'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _future = _service.getSummary()),
                    child: const Text('حاول تاني'),
                  ),
                ],
              ),
            );
          }

          final s = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'التقرير الشامل',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ملخص كل حركة البيع والشراء والمصروفات والمرتجعات',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ReportCard(title: 'صافي المبيعات', value: _money(s.netSales), icon: Icons.shopping_cart_outlined),
                    _ReportCard(title: 'صافي المشتريات', value: _money(s.netPurchases), icon: Icons.inventory_2_outlined),
                    _ReportCard(title: 'المصروفات', value: _money(s.expensesTotal), icon: Icons.payments_outlined),
                    _ReportCard(title: 'الصافي', value: _money(s.net), icon: Icons.trending_up_outlined),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E9EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('تفاصيل التقرير', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _row('فواتير البيع', '${s.salesCount}'),
                      _row('فواتير الشراء', '${s.purchasesCount}'),
                      _row('مرتجعات البيع', '${s.salesReturnsCount} — ${_money(s.salesReturnsTotal)}'),
                      _row('مرتجعات الشراء', '${s.purchaseReturnsCount} — ${_money(s.purchaseReturnsTotal)}'),
                      _row('المصروفات', '${s.expensesCount} — ${_money(s.expensesTotal)}'),
                      _row('المنتجات', '${s.productsCount}'),
                      _row('الموردين', '${s.suppliersCount}'),
                      _row('العملاء', '${s.customersCount}'),
                      _row('قيمة المخزون', _money(s.stockValue)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E9EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 14),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
