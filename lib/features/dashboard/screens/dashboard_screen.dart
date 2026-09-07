import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/Products/screens/add_product_screen.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/dashboard/widgets/inventory_status_card.dart';
import 'package:dafter/features/dashboard/widgets/receivables_card.dart';
import 'package:dafter/features/dashboard/widgets/summary_card.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_return.dart';
import 'package:dafter/features/purchases/screens/purchase_invoice_screen.dart';
import 'package:dafter/features/sales/repo/sale_return_repository.dart';
import 'package:dafter/features/sales/repo/sales_repository.dart';
import 'package:dafter/features/sales/screens/sales_invoice_screen.dart';
import 'package:dafter/features/sales/screens/sales_return_screen.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _salesRepository = SalesRepository();
  final _saleReturnRepository = SaleReturnRepository();
  final _productRepository = ProductRepository();
  final _customerRepository = CustomerRepository();
  final _supplierRepository = SupplierRepository();
  bool _loading = true;
  List<Sale> _sales = [];
  List<SaleReturn> _saleReturns = [];
  List<Product> _products = [];
  double _customerDue = 0;
  double _supplierDue = 0;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _salesRepository.getSales(), _saleReturnRepository.getReturns(), _productRepository.getProducts(),
        _customerRepository.getCustomers(), _supplierRepository.getSuppliers(),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = results[0] as List<Sale>;
        _saleReturns = results[1] as List<SaleReturn>;
        _products = results[2] as List<Product>;
        _customerDue = (results[3] as List).fold<double>(0, (sum, item) => sum + (item.balance as double));
        _supplierDue = (results[4] as List).fold<double>(0, (sum, item) => sum + (item.balance as double));
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  List<Sale> get _todaySales { final now = DateTime.now(); return _sales.where((sale) => _sameDay(sale.date, now)).toList(); }
  double get _todayTotal {
    final now = DateTime.now();
    final sales = _todaySales.fold<double>(0, (sum, sale) => sum + sale.total);
    final returns = _saleReturns.where((r) => _sameDay(r.date, now)).fold<double>(0, (sum, r) => sum + r.total);
    return sales - returns;
  }
  double get _todayProfit {
    final now = DateTime.now();
    var profit = _todaySales.fold<double>(0, (sum, sale) => sum + sale.total - sale.items.fold<double>(0, (s, item) => s + item.costTotal));
    for (final saleReturn in _saleReturns.where((r) => _sameDay(r.date, now))) {
      var returnedCost = 0.0;
      final sale = _sales.where((s) => s.id == saleReturn.saleId).firstOrNull;
      for (final item in saleReturn.items) {
        final original = sale?.items.where((s) => s.id == item.saleItemId).firstOrNull;
        returnedCost += (original?.costPrice ?? 0) * item.quantity;
      }
      profit -= saleReturn.total - returnedCost;
    }
    return profit;
  }
  int get _lowStock => _products.where((p) => p.quantity > 0 && p.quantity <= p.minQuantity).length;
  int get _outOfStock => _products.where((p) => p.quantity <= 0).length;
  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';
  Future<void> _open(Widget screen) async { await Navigator.push(context, MaterialPageRoute(builder: (_) => screen)); _load(); }

  @override Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SafeArea(child: RefreshIndicator(onRefresh: _load, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: ActionButton(icon: Icons.assignment_return_outlined, label: 'مرتجع بيع', primary: false, onTap: () => _open(const SalesReturnScreen()))), const SizedBox(width: 12),
        Expanded(child: ActionButton(icon: Icons.add_box_outlined, label: 'إضافة منتج', primary: false, onTap: () => _open(const AddProductScreen()))), const SizedBox(width: 12),
        Expanded(child: ActionButton(icon: Icons.receipt_long_outlined, label: 'فاتورة شراء', primary: false, onTap: () => _open(const PurchaseInvoiceScreen()))), const SizedBox(width: 12),
        Expanded(child: ActionButton(icon: Icons.shopping_cart_outlined, label: 'فاتورة بيع', primary: true, onTap: () => _open(const SalesInvoiceScreen()))),
      ]), const SizedBox(height: 20),
      Row(children: [
        Expanded(child: SummaryCard(icon: Icons.account_balance_wallet_outlined, iconBg: const Color(0xFFF3E9DD), iconColor: const Color(0xFF9C6B30), value: _money(_todayProfit), label: 'مكسب النهارده')), const SizedBox(width: 16),
        Expanded(child: SummaryCard(icon: Icons.description_outlined, iconBg: const Color(0xFFF1F3F4), iconColor: Colors.grey, value: '${_todaySales.length} فاتورة', label: 'فواتير النهارده')), const SizedBox(width: 16),
        Expanded(child: SummaryCard(icon: Icons.trending_up, iconBg: const Color(0xFFDDEDEC), iconColor: const Color(0xFF0E4C4C), value: _money(_todayTotal), label: 'صافي مبيعات النهارده')),
      ]), const SizedBox(height: 20),
      InventoryStatusCard(totalProducts: _products.length, lowStock: _lowStock, outOfStock: _outOfStock), const SizedBox(height: 20),
      ReceivablesCard(customerDue: _money(_customerDue), supplierDue: _money(_supplierDue)), const SizedBox(height: 20), _SalesWeekCard(sales: _sales),
    ]))));
  }
}

class _SalesWeekCard extends StatelessWidget {
  final List<Sale> sales; const _SalesWeekCard({required this.sales});
  @override Widget build(BuildContext context) {
    final now = DateTime.now();
    final data = List.generate(7, (index) { final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index)); final total = sales.where((sale) => sale.date.year == day.year && sale.date.month == day.month && sale.date.day == day.day).fold<double>(0, (sum, sale) => sum + sale.total); return (day, total); });
    final max = data.fold<double>(0, (m, item) => item.$2 > m ? item.$2 : m);
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('مبيعات آخر 7 أيام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      SizedBox(height: 210, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: data.map((item) { final height = max == 0 ? 0.0 : (item.$2 / max) * 145; return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text(item.$2.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 5), Container(height: height, width: double.infinity, decoration: const BoxDecoration(color: Color(0xFF0E4C4C), borderRadius: BorderRadius.vertical(top: Radius.circular(6)))), const SizedBox(height: 8), Text(_dayName(item.$1.weekday), style: const TextStyle(fontSize: 10, color: Colors.grey))]))); }).toList()))
    ]));
  }
  String _dayName(int day) => const ['الإتنين', 'التلات', 'الأربع', 'الخميس', 'الجمعة', 'السبت', 'الأحد'][day - 1];
}
