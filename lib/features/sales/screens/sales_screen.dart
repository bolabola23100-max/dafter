import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/sales/repo/sale_return_repository.dart';
import 'package:dafter/features/sales/repo/sales_repository.dart';
import 'package:dafter/features/sales/screens/sales_invoice_screen.dart';
import 'package:dafter/features/sales/screens/sales_return_screen.dart';
import 'package:flutter/material.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _repository = SalesRepository();
  final _returns = SaleReturnRepository();
  final _productRepository = ProductRepository();
  List<Sale> _sales = [];
  Map<String, double> _returnedTotals = {};
  Map<String, double> _refundedTotals = {};
  Map<String, Product> _products = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repository.getSales(),
        _returns.getReturns(),
        _productRepository.getProducts(),
      ]);
      final sales = results[0] as List<Sale>;
      final returns = results[1] as List<dynamic>;
      final products = results[2] as List<Product>;
      final totals = <String, double>{};
      final refunds = <String, double>{};
      for (final r in returns) {
        totals.update(r.saleId, (v) => v + r.total, ifAbsent: () => r.total);
        refunds.update(r.saleId, (v) => v + r.refundedAmount, ifAbsent: () => r.refundedAmount);
      }
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _returnedTotals = totals;
        _refundedTotals = refunds;
        _products = {for (final product in products) product.id: product};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('حصلت مشكلة وإحنا بنجيب المبيعات');
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  double _adjustedRemaining(Sale sale, String saleId) {
    final returned = _returnedTotals[saleId] ?? 0;
    final refunded = _refundedTotals[saleId] ?? 0;
    final amountAppliedToBalance = (returned - refunded).clamp(0, double.infinity);
    return (sale.remainingAmount - amountAppliedToBalance).clamp(0, double.infinity).toDouble();
  }

  Future<void> _showSaleDetails(Sale sale) async {
    final saleReturns = await _returns.getReturnsBySale(sale.id);
    if (!mounted) return;
    final returnedByItem = <String, int>{};
    for (final saleReturn in saleReturns) {
      for (final item in saleReturn.items) {
        returnedByItem.update(item.saleItemId, (value) => value + item.quantity, ifAbsent: () => item.quantity);
      }
    }
    final returnedTotal = saleReturns.fold<double>(0, (sum, saleReturn) => sum + saleReturn.total);
    final refundedTotal = saleReturns.fold<double>(0, (sum, saleReturn) => sum + saleReturn.refundedAmount);
    final net = sale.total - returnedTotal;
    final remainingBalance = (sale.remainingAmount - (returnedTotal - refundedTotal).clamp(0, double.infinity)).clamp(0, double.infinity).toDouble();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(sale.displayInvoiceNumber),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('التاريخ: ${_date(sale.date)}'),
                const SizedBox(height: 8),
                Text('إجمالي الفاتورة الأصلي: ${_money(sale.total)}'),
                if (returnedTotal > 0) ...[
                  const SizedBox(height: 4),
                  Text('إجمالي المرتجع: ${_money(returnedTotal)}'),
                  const SizedBox(height: 4),
                  Text('الفلوس المرتجعة: ${_money(refundedTotal)}'),
                ],
                const SizedBox(height: 4),
                Text('صافي المبيعات: ${_money(net)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('المتبقي على العميل الآن: ${_money(remainingBalance)}'),
                const Divider(height: 28),
                const Text('الأصناف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...sale.items.map((item) {
                  final returned = returnedByItem[item.id] ?? 0;
                  final remaining = (item.quantity - returned).clamp(0, item.quantity).toInt();
                  final productName = _products[item.productId]?.name ?? item.productId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E9EB)), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(productName)),
                        Expanded(child: Text('باع: ${item.quantity}')),
                        Expanded(child: Text('مرتجع: $returned')),
                        Expanded(child: Text('متاح: $remaining', style: TextStyle(fontWeight: FontWeight.bold, color: remaining == 0 ? Colors.grey : null))),
                        Expanded(child: Text(_money(item.subtotal))),
                      ],
                    ),
                  );
                }),
                if (saleReturns.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('مفيش مرتجعات على الفاتورة دي.')),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _sales.fold<double>(0, (s, sale) => s + sale.total);
    final returned = _returnedTotals.values.fold<double>(0, (s, v) => s + v);
    final remaining = _sales.fold<double>(0, (s, sale) => s + _adjustedRemaining(sale, sale.id));
    final netSales = total - returned;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المبيعات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('كل فواتير البيع والمرتجعات والمدفوعات', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              OutlinedButton.icon(onPressed: () => _open(const SalesReturnScreen()), icon: const Icon(Icons.assignment_return_outlined), label: const Text('مرتجع بيع')),
              const SizedBox(width: 10),
              FilledButton.icon(onPressed: () => _open(const SalesInvoiceScreen()), icon: const Icon(Icons.add), label: const Text('فاتورة بيع جديدة')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _summary('إجمالي البيع', total, Icons.shopping_cart_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _summary('المرتجعات', returned, Icons.assignment_return_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _summary('صافي المبيعات', netSales, Icons.trending_up)),
              const SizedBox(width: 12),
              Expanded(child: _summary('الباقي', remaining, Icons.pending_actions_outlined)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? const Center(child: Text('لسه مفيش فواتير بيع'))
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _sales.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final sale = _sales[index];
                            final returnTotal = _returnedTotals[sale.id] ?? 0;
                            final net = sale.total - returnTotal;
                            final adjustedRemaining = _adjustedRemaining(sale, sale.id);
                            final status = adjustedRemaining <= 0 ? 'مدفوعة' : sale.paidAmount > 0 ? 'جزئي' : 'آجل';
                            return ListTile(
                              onTap: () => _showSaleDetails(sale),
                              leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                              title: Text(sale.displayInvoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${_date(sale.date)} • ${sale.items.length} أصناف • $status${returnTotal > 0 ? ' • مرتجع ${_money(returnTotal)}' : ''}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('صافي ${_money(net)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (returnTotal > 0) Text('الأصلي ${_money(sale.total)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  if (adjustedRemaining > 0) Text('باقي ${_money(adjustedRemaining)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _summary(String title, double value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(_money(value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
