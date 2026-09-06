import 'package:flutter/material.dart';

class RecentInvoices extends StatelessWidget {
  const RecentInvoices({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = [
      _Invoice(
        number: '#1025',
        name: 'محمد أحمد',
        type: 'بيع',
        total: '2,450 ج.م',
        time: '02:30 م',
      ),
      _Invoice(
        number: '#1024',
        name: 'مؤسسة النور',
        type: 'بيع',
        total: '1,200 ج.م',
        time: '01:15 م',
      ),
      _Invoice(
        number: '#1023',
        name: 'مورد الإكسسوارات',
        type: 'شراء',
        total: '4,800 ج.م',
        time: '12:40 م',
      ),
      _Invoice(
        number: '#1022',
        name: 'أحمد محمد',
        type: 'بيع',
        total: '850 ج.م',
        time: '11:20 ص',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'آخر الفواتير',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('عرض الكل')),
            ],
          ),

          const SizedBox(height: 12),

          _HeaderRow(),

          const Divider(height: 1, color: Color(0xFFE5E9EB)),

          ...invoices.map(
            (invoice) => _InvoiceRow(invoice: invoice, onTap: () {}),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'رقم الفاتورة',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'العميل / المورد',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              'النوع',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              'الإجمالي',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              'الوقت',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final _Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F1F2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                invoice.number,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Expanded(flex: 2, child: Text(invoice.name)),

            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: invoice.type == 'بيع'
                        ? const Color(0xFFDDEDEC)
                        : const Color(0xFFF3E9DD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    invoice.type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: invoice.type == 'بيع'
                          ? const Color(0xFF0E4C4C)
                          : const Color(0xFF9C6B30),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Text(
                invoice.total,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Expanded(
              child: Text(
                invoice.time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Invoice {
  final String number;
  final String name;
  final String type;
  final String total;
  final String time;

  const _Invoice({
    required this.number,
    required this.name,
    required this.type,
    required this.total,
    required this.time,
  });
}
