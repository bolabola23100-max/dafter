import 'package:flutter/material.dart';

class FullReportScreen extends StatelessWidget {
  const FullReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقرير الشامل')),
      body: SingleChildScrollView(
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
              'ملخص شامل لحركة النشاط خلال الفترة المحددة',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _ReportCard(
                    title: 'إجمالي المبيعات',
                    value: '45,000.00',
                    icon: Icons.shopping_cart_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportCard(
                    title: 'إجمالي المشتريات',
                    value: '27,500.00',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportCard(
                    title: 'إجمالي المصروفات',
                    value: '7,650.00',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ReportCard(
                    title: 'صافي الربح',
                    value: '9,850.00',
                    icon: Icons.trending_up_outlined,
                  ),
                ),
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
                  const Text(
                    'تفاصيل التقرير',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  _row('عدد فواتير البيع', '125'),
                  _row('عدد فواتير الشراء', '48'),
                  _row('عدد المرتجعات', '7'),
                  _row('عدد المنتجات', '1,250'),
                  _row('عدد الموردين', '24'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
