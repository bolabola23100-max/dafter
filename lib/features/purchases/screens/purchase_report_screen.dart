import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:flutter/material.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  final _purchaseRepository = PurchaseRepository();
  final _supplierRepository = SupplierRepository();
  final _searchController = TextEditingController();

  List<Purchase> _purchases = [];
  Map<String, String> _supplierNames = {};
  bool _loading = true;
  String _filter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<Object>([
        _purchaseRepository.getPurchases(),
        _supplierRepository.getSuppliers(),
      ]);
      final purchases = results[0] as List<Purchase>;
      final suppliers = results[1] as List<Supplier>;

      if (!mounted) return;
      setState(() {
        _purchases = purchases;
        _supplierNames = {
          for (final supplier in suppliers) supplier.id: supplier.name,
        };
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('حصلت مشكلة وأنا بجيب تقرير المشتريات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Purchase> get _filteredPurchases {
    final query = _searchController.text.trim().toLowerCase();
    return _purchases.where((purchase) {
      final supplier = _supplierNames[purchase.supplierId] ?? 'بدون مورد';
      final remaining = purchase.remainingAmount;
      final matchesFilter = switch (_filter) {
        'مدفوع' => remaining <= 0.009,
        'آجل' => remaining > 0.009,
        _ => true,
      };
      final matchesSearch = query.isEmpty ||
          purchase.id.toLowerCase().contains(query) ||
          supplier.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  double get _total =>
      _filteredPurchases.fold(0, (sum, item) => sum + item.total);
  double get _paid =>
      _filteredPurchases.fold(0, (sum, item) => sum + item.paidAmount);
  double get _remaining =>
      _filteredPurchases.fold(0, (sum, item) => sum + item.remainingAmount);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchases = _filteredPurchases;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(
        title: const Text('كشف المشتريات'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummary(),
            const SizedBox(height: 18),
            _buildToolbar(),
            const SizedBox(height: 18),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : purchases.isEmpty
                      ? _buildEmptyState()
                      : _buildTable(purchases),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _stat(
            'إجمالي المشتريات',
            _total,
            Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: _stat('المدفوع', _paid, Icons.payments_outlined)),
        const SizedBox(width: 14),
        Expanded(
          child: _stat('المستحق', _remaining, Icons.money_off_outlined),
        ),
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
            child: TextField(
              controller: _searchController,
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
                selected: _filter == item,
                onSelected: (_) => setState(() => _filter = item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Purchase> purchases) {
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
              itemCount: purchases.length,
              itemBuilder: (_, index) {
                final purchase = purchases[index];
                final supplier =
                    _supplierNames[purchase.supplierId] ?? 'بدون مورد';
                final remaining = purchase.remainingAmount;
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
                          '#${purchase.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(flex: 2, child: Text(supplier)),
                      Expanded(
                        child: Text('${purchase.total.toStringAsFixed(2)} ج.م'),
                      ),
                      Expanded(
                        child: Text(
                          '${purchase.paidAmount.toStringAsFixed(2)} ج.م',
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${remaining.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            color: remaining <= 0.009
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatDate(purchase.date),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text(
            'مفيش فواتير مشتريات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _searchController.text.isEmpty && _filter == 'الكل'
                ? 'لما تضيف أول فاتورة هتظهر هنا.'
                : 'جرّب تغيّر البحث أو الفلتر.',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
