import 'package:flutter/material.dart';

class SupplierStatementScreen extends StatefulWidget {
  const SupplierStatementScreen({super.key});

  @override
  State<SupplierStatementScreen> createState() =>
      _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
  String? selectedSupplier;

  final transactions = const [
    _Transaction(
      date: '30/08/2026',
      description: 'فاتورة شراء #1025',
      debit: 5000,
      credit: 0,
    ),
    _Transaction(
      date: '29/08/2026',
      description: 'سداد دفعة',
      debit: 0,
      credit: 2000,
    ),
    _Transaction(
      date: '27/08/2026',
      description: 'فاتورة شراء #1018',
      debit: 3500,
      credit: 0,
    ),
  ];

  double get totalPurchases =>
      transactions.fold(0, (sum, item) => sum + item.debit);

  double get totalPayments =>
      transactions.fold(0, (sum, item) => sum + item.credit);

  double get balance => totalPurchases - totalPayments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'كشف حساب المورد',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSupplierSelector(),

            const SizedBox(height: 18),

            _buildSummary(),

            const SizedBox(height: 18),

            _buildTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          const Icon(Icons.store_outlined, color: Color(0xFF0E4C4C)),
          const SizedBox(width: 12),
          const Text('المورد:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 15),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              initialValue: selectedSupplier,
              hint: const Text('اختر المورد'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              items:
                  const [
                        'شركة النور',
                        'أحمد للإكسسوارات',
                        'مؤسسة الأمل',
                        'مورد الإكسسوارات',
                      ]
                      .map(
                        (supplier) => DropdownMenuItem(
                          value: supplier,
                          child: Text(supplier),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSupplier = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _Summary(
            title: 'إجمالي المشتريات',
            value: '${totalPurchases.toStringAsFixed(2)} ج.م',
            icon: Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _Summary(
            title: 'إجمالي المدفوع',
            value: '${totalPayments.toStringAsFixed(2)} ج.م',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _Summary(
            title: 'الرصيد المستحق',
            value: '${balance.toStringAsFixed(2)} ج.م',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الحركات',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF7F8F9),
            child: const Row(
              children: [
                Expanded(child: Text('التاريخ')),
                Expanded(flex: 2, child: Text('البيان')),
                Expanded(child: Text('مدين')),
                Expanded(child: Text('دائن')),
              ],
            ),
          ),

          ...transactions.map(
            (transaction) => Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F1F2))),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(transaction.date)),
                  Expanded(flex: 2, child: Text(transaction.description)),
                  Expanded(
                    child: Text(
                      transaction.debit == 0
                          ? '-'
                          : '${transaction.debit.toStringAsFixed(2)} ج.م',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      transaction.credit == 0
                          ? '-'
                          : '${transaction.credit.toStringAsFixed(2)} ج.م',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E9EB)),
    );
  }
}

class _Summary extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Summary({
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
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0E4C4C)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Transaction {
  final String date;
  final String description;
  final double debit;
  final double credit;

  const _Transaction({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
  });
}
