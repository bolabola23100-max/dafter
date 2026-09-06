import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  final searchController = TextEditingController();

  String filter = 'الكل';

  final List<ReportPurchase> purchases = [
    ReportPurchase(
      invoice: '1025',
      supplier: 'شركة النور',
      total: 12500,
      paid: 8000,
      date: '30/08/2026',
      type: 'آجل',
    ),
    ReportPurchase(
      invoice: '1024',
      supplier: 'أحمد للإكسسوارات',
      total: 6800,
      paid: 6800,
      date: '29/08/2026',
      type: 'نقدي',
    ),
    ReportPurchase(
      invoice: '1023',
      supplier: 'مؤسسة الأمل',
      total: 15400,
      paid: 10000,
      date: '28/08/2026',
      type: 'آجل',
    ),
  ];

  List<ReportPurchase> get result {
    var data = purchases;

    if (filter != 'الكل') {
      data = data.where((item) {
        if (filter == 'مدفوع') {
          return item.remaining == 0;
        }

        if (filter == 'آجل') {
          return item.type == 'آجل';
        }

        return true;
      }).toList();
    }

    final query = searchController.text.trim();

    if (query.isNotEmpty) {
      data = data.where((item) {
        return item.invoice.contains(query) || item.supplier.contains(query);
      }).toList();
    }

    return data;
  }

  double get total {
    return purchases.fold(0, (sum, item) => sum + item.total);
  }

  double get paid {
    return purchases.fold(0, (sum, item) => sum + item.paid);
  }

  double get remaining {
    return total - paid;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('كشف المشتريات'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummary(),

            const SizedBox(height: 18),

            _buildToolbar(),

            const SizedBox(height: 18),

            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _stat('إجمالي المشتريات', total, Icons.shopping_bag_outlined),
        ),
        const SizedBox(width: 14),
        Expanded(child: _stat('المدفوع', paid, Icons.payments_outlined)),
        const SizedBox(width: 14),
        Expanded(child: _stat('المستحق', remaining, Icons.money_off_outlined)),
      ],
    );
  }

  Widget _stat(String title, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${value.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            height: 42,
            child: CustomTextFormField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث برقم الفاتورة أو المورد',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF7F8F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Spacer(),

          ...['الكل', 'مدفوع', 'آجل'].map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(item),
                selected: filter == item,
                onSelected: (_) {
                  setState(() {
                    filter = item;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(color: Color(0xFFF7F8F9)),
            child: const Row(
              children: [
                Expanded(child: Text('الفاتورة')),
                Expanded(flex: 2, child: Text('المورد')),
                Expanded(child: Text('الإجمالي')),
                Expanded(child: Text('المدفوع')),
                Expanded(child: Text('المتبقي')),
                Expanded(child: Text('التاريخ')),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: result.length,
              itemBuilder: (_, index) {
                final item = result[index];

                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F1F2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${item.invoice}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(flex: 2, child: Text(item.supplier)),
                      Expanded(
                        child: Text('${item.total.toStringAsFixed(2)} ج.م'),
                      ),
                      Expanded(
                        child: Text('${item.paid.toStringAsFixed(2)} ج.م'),
                      ),
                      Expanded(
                        child: Text(
                          '${item.remaining.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            color: item.remaining == 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.date,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReportPurchase {
  final String invoice;
  final String supplier;
  final double total;
  final double paid;
  final String date;
  final String type;

  const ReportPurchase({
    required this.invoice,
    required this.supplier,
    required this.total,
    required this.paid,
    required this.date,
    required this.type,
  });

  double get remaining => total - paid;
}
