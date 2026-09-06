import 'package:dafter/features/model/sale.dart';
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
  final SalesRepository _repository = SalesRepository();
  List<Sale> _sales = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sales = await _repository.getSales();
      if (!mounted) return;
      setState(() { _sales = sales; _loading = false; });
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

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';
  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final total = _sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final paid = _sales.fold<double>(0, (sum, sale) => sum + sale.paidAmount);
    final remaining = _sales.fold<double>(0, (sum, sale) => sum + sale.remainingAmount);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المبيعات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('كل فواتير البيع واللي اتدفع واللي لسه', style: TextStyle(color: Colors.grey)),
          ])),
          OutlinedButton.icon(onPressed: () => _open(const SalesReturnScreen()), icon: const Icon(Icons.assignment_return_outlined), label: const Text('مرتجع بيع')),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: () => _open(const SalesInvoiceScreen()), icon: const Icon(Icons.add), label: const Text('فاتورة بيع جديدة')),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _summary('إجمالي البيع', total, Icons.shopping_cart_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _summary('اللي اتدفع', paid, Icons.payments_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _summary('الباقي', remaining, Icons.pending_actions_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _summary('عدد الفواتير', _sales.length.toDouble(), Icons.receipt_long_outlined, money: false)),
        ]),
        const SizedBox(height: 20),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
            ? const Center(child: Text('لسه مفيش فواتير بيع'))
            : Card(
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  itemCount: _sales.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    final status = sale.remainingAmount <= 0 ? 'مدفوعة' : sale.paidAmount > 0 ? 'جزئي' : 'آجل';
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                      title: Text('فاتورة بيع #${sale.id}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${_date(sale.date)} • ${sale.items.length} أصناف • $status'),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(_money(sale.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (sale.remainingAmount > 0) Text('باقي ${_money(sale.remainingAmount)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ]),
                    );
                  },
                ),
              )),
      ]),
    );
  }

  Widget _summary(String title, double value, IconData icon, {bool money = true}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(icon), const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(money ? _money(value) : value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ])),
      ]),
    ),
  );
}
