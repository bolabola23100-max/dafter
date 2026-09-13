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
  List<Sale> _sales = [];
  Map<String, double> _returnedTotals = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final sales = await _repository.getSales();
      final returns = await _returns.getReturns();
      final totals = <String, double>{};
      for (final r in returns) {
        totals.update(
          r.saleId,
          (v) => v + r.total,
          ifAbsent: () => r.total,
        );
      }
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _returnedTotals = totals;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('حصلت مشكلة وإحنا بنجيب المبيعات');
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await _load();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _showSaleDetails(Sale sale) async {
    final saleReturns = await _returns.getReturnsBySale(sale.id);
    if (!mounted) return;

    final returnedByItem = <String, int>{};
    for (final saleReturn in saleReturns) {
      for (final item in saleReturn.items) {
        returnedByItem.update(
          item.saleItemId,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    final returnedTotal = saleReturns.fold<double>(
      0,
      (sum, saleReturn) => sum + saleReturn.total,
    );
    final net = sale.total - returnedTotal;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('تفاصيل فاتورة البيع #${sale.id}'),
          content: SizedBox(
            width: 760,
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
                    Text(
                      'صافي المبيعات: ${_money(net)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                  const Divider(height: 28),
                  const Text(
                    'الأصناف',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...sale.items.map((item) {
                    final returned = returnedByItem[item.id] ?? 0;
                    final remaining = (item.quantity - returned).clamp(0, item.quantity);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E9EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('منتج: ${item.productId}'),
                          ),
                          Expanded(child: Text('باع: ${item.quantity}')),
                          Expanded(child: Text('مرتجع: $returned')),
                          Expanded(
                            child: Text(
                              'متبقي: $remaining',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: remaining == 0 ? Colors.grey : null,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(_money(item.subtotal)),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (saleReturns.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('مفيش مرتجعات على الفاتورة دي.'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _sales.fold<double>(0, (s, sale) => s + sale.total);
    final returned = _returnedTotals.values.fold<double>(0, (s, v) => s + v);
    final paid = _sales.fold<double>(0, (s, sale) => s + sale.paidAmount);
    final remaining =
        _sales.fold<double>(0, (s, sale) => s + sale.remainingAmount);
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
                    Text(
                      'المبيعات',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'كل فواتير البيع والمرتجعات والمدفوعات',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _open(const SalesReturnScreen()),
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('مرتجع بيع'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _open(const SalesInvoiceScreen()),
                icon: const Icon(Icons.add),
                label: const Text('فاتورة بيع جديدة'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _summary(
                  'إجمالي البيع',
                  total,
                  Icons.shopping_cart_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summary(
                  'المرتجعات',
                  returned,
                  Icons.assignment_return_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summary(
                  'صافي المبيعات',
                  netSales,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summary(
                  'الباقي',
                  remaining,
                  Icons.pending_actions_outlined,
                ),
              ),
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
                            final status = sale.remainingAmount <= 0
                                ? 'مدفوعة'
                                : sale.paidAmount > 0
                                    ? 'جزئي'
                                    : 'آجل';

                            return ListTile(
                              onTap: () => _showSaleDetails(sale),
                              leading: const CircleAvatar(
                                child: Icon(Icons.receipt_long_outlined),
                              ),
                              title: Text(
                                'فاتورة بيع #${sale.id}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${_date(sale.date)} • ${sale.items.length} أصناف • $status${returnTotal > 0 ? ' • مرتجع ${_money(returnTotal)}' : ''}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'صافي ${_money(net)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (returnTotal > 0)
                                    Text(
                                      'الأصلي ${_money(sale.total)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  if (sale.remainingAmount > 0)
                                    Text(
                                      'باقي ${_money(sale.remainingAmount)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
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
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _money(value),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
