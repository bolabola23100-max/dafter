import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:flutter/material.dart';

class SupplierStatementScreen extends StatefulWidget {
  final String? supplierId;

  const SupplierStatementScreen({super.key, this.supplierId});

  @override
  State<SupplierStatementScreen> createState() => _SupplierStatementScreenState();
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
    selectedSupplierId = widget.supplierId;
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final result = await _supplierRepository.getSuppliers();
      if (!mounted) return;
      setState(() {
        suppliers = result;
        _isLoading = false;
        if (selectedSupplierId != null && !result.any((s) => s.id == selectedSupplierId)) {
          selectedSupplierId = null;
        }
      });
      if (selectedSupplierId != null) await _loadStatement(selectedSupplierId!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('حصلت مشكلة وإحنا بنجيب الموردين');
    }
  }

  Future<void> _loadStatement(String id) async {
    setState(() {
      purchases = [];
      payments = [];
      _isLoading = true;
    });
    try {
      final result = await Future.wait([
        _purchaseRepository.getPurchasesBySupplier(id),
        _supplierRepository.getSupplierPayments(id),
      ]);
      if (!mounted) return;
      setState(() {
        purchases = result[0] as List<Purchase>;
        payments = result[1] as List<Payment>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('حصلت مشكلة وإحنا بنجيب كشف الحساب');
    }
  }

  Future<void> _selectSupplier(String? id) async {
    setState(() => selectedSupplierId = id);
    if (id != null) await _loadStatement(id);
  }

  Supplier? get selectedSupplier => suppliers.where((s) => s.id == selectedSupplierId).firstOrNull;
  double get totalPurchases => purchases.fold(0, (sum, p) => sum + p.total);
  double get totalPayments => payments.fold(0, (sum, p) => sum + p.amount);
  double get openingBalance => selectedSupplier?.openingBalance ?? 0;
  double get balance => selectedSupplier?.balance ?? 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';
  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(title: const Text('كشف حساب المورد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _selector(),
            const SizedBox(height: 18),
            if (selectedSupplierId == null)
              _empty()
            else ...[
              _summary(),
              const SizedBox(height: 18),
              _transactions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selector() => Container(
    padding: const EdgeInsets.all(18),
    decoration: _box(),
    child: Row(
      children: [
        const Icon(Icons.store_outlined),
        const SizedBox(width: 12),
        const Text('المورد'),
        const SizedBox(width: 15),
        SizedBox(
          width: 360,
          child: DropdownButtonFormField<String>(
            initialValue: selectedSupplierId,
            hint: const Text('اختار المورد'),
            items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: _selectSupplier,
          ),
        ),
      ],
    ),
  );

  Widget _summary() => Row(
    children: [
      Expanded(child: _Summary(title: 'الرصيد الأول', value: _money(openingBalance), icon: Icons.account_balance_wallet_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _Summary(title: 'المشتريات', value: _money(totalPurchases), icon: Icons.shopping_bag_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _Summary(title: 'اللي اتدفع', value: _money(totalPayments), icon: Icons.payments_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _Summary(title: 'له عندنا دلوقتي', value: _money(balance), icon: Icons.account_balance_wallet_outlined)),
    ],
  );

  Widget _transactions() {
    final rows = <_Transaction>[];
    for (final purchase in purchases) {
      rows.add(_Transaction(date: purchase.date, description: 'فاتورة شراء #${purchase.id}', debit: purchase.total, credit: 0));
    }
    for (final payment in payments) {
      rows.add(_Transaction(date: payment.date, description: payment.notes?.isNotEmpty == true ? payment.notes! : 'سداد دفعة', debit: 0, credit: payment.amount));
    }
    rows.sort((a, b) => b.date.compareTo(a.date));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('الحركات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
          else if (rows.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لسه مفيش حركات للمورد ده')))
          else
            ...rows.map((row) => ListTile(
              leading: Icon(row.debit > 0 ? Icons.receipt_long_outlined : Icons.payments_outlined),
              title: Text(row.description),
              subtitle: Text(_date(row.date)),
              trailing: Text(row.debit > 0 ? 'عليه ${_money(row.debit)}' : 'دفع ${_money(row.credit)}'),
            )),
        ],
      ),
    );
  }

  Widget _empty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(50),
    decoration: _box(),
    child: const Column(children: [Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey), SizedBox(height: 12), Text('اختار مورد عشان تشوف حسابه')]),
  );

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB)));
}

class _Summary extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _Summary({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
    child: Row(children: [Icon(icon), const SizedBox(width: 10), Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]))]),
  );
}

class _Transaction {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  const _Transaction({required this.date, required this.description, required this.debit, required this.credit});
}
