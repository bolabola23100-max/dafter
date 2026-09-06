import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:flutter/material.dart';

class SupplierStatementScreen extends StatefulWidget {
  const SupplierStatementScreen({super.key});

  @override
  State<SupplierStatementScreen> createState() =>
      _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
  final _supplierRepository = SupplierRepository();
  final _purchaseRepository = PurchaseRepository();

  List<Supplier> suppliers = [];
  List<Purchase> purchases = [];
  List<Payment> payments = [];
  String? selectedSupplierId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final result = await _supplierRepository.getSuppliers();
      if (!mounted) return;
      setState(() {
        suppliers = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('حدث خطأ أثناء تحميل الموردين: $e');
    }
  }

  Future<void> _selectSupplier(String? id) async {
    setState(() {
      selectedSupplierId = id;
      purchases = [];
      payments = [];
      _isLoading = id != null;
    });

    if (id == null) return;

    try {
      final loadedPurchases = await _purchaseRepository.getPurchasesBySupplier(id);
      final loadedPayments = await _supplierRepository.getSupplierPayments(id);

      if (!mounted) return;
      setState(() {
        purchases = loadedPurchases;
        payments = loadedPayments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('حدث خطأ أثناء تحميل كشف الحساب: $e');
    }
  }

  Supplier? get selectedSupplier {
    for (final supplier in suppliers) {
      if (supplier.id == selectedSupplierId) return supplier;
    }
    return null;
  }

  double get totalPurchases =>
      purchases.fold(0, (sum, purchase) => sum + purchase.total);

  double get totalPayments =>
      payments.fold(0, (sum, payment) => sum + payment.amount);

  double get openingBalance => selectedSupplier?.openingBalance ?? 0;

  double get balance => selectedSupplier?.balance ?? 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

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
      ),
      body: _isLoading && suppliers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSupplierSelector(),
                  const SizedBox(height: 18),
                  if (selectedSupplierId != null) ...[
                    _buildSummary(),
                    const SizedBox(height: 18),
                    _buildTransactions(),
                  ] else
                    _emptyState(),
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
            width: 360,
            child: DropdownButtonFormField<String>(
              initialValue: selectedSupplierId,
              hint: const Text('اختر المورد'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              items: suppliers
                  .map(
                    (supplier) => DropdownMenuItem<String>(
                      value: supplier.id,
                      child: Text(supplier.name),
                    ),
                  )
                  .toList(),
              onChanged: _selectSupplier,
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
            title: 'الرصيد الافتتاحي',
            value: '${openingBalance.toStringAsFixed(2)} ج.م',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 15),
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
            title: 'المستحق حاليًا',
            value: '${balance.toStringAsFixed(2)} ج.م',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    final rows = <_Transaction>[];

    for (final purchase in purchases) {
      rows.add(
        _Transaction(
          date: purchase.date,
          description: 'فاتورة شراء #${purchase.id}',
          debit: purchase.total,
          credit: 0,
        ),
      );
    }

    for (final payment in payments) {
      rows.add(
        _Transaction(
          date: payment.date,
          description: payment.notes?.isNotEmpty == true
              ? payment.notes!
              : 'سداد دفعة',
          debit: 0,
          credit: payment.amount,
        ),
      );
    }

    if (openingBalance > 0) {
      rows.add(
        _Transaction(
          date: selectedSupplier == null
              ? DateTime.now()
              : DateTime.now(),
          description: 'الرصيد الافتتاحي',
          debit: openingBalance,
          credit: 0,
        ),
      );
    }

    rows.sort((a, b) => b.date.compareTo(a.date));

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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('لا توجد حركات لهذا المورد')),
            )
          else ...[
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
            ...rows.map(
              (transaction) => Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F1F2))),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(_date(transaction.date))),
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
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: _boxDecoration(),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey),
          SizedBox(height: 12),
          Text('اختر موردًا لعرض كشف حسابه'),
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

  const _Summary({required this.title, required this.value, required this.icon});

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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Transaction {
  final DateTime date;
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
