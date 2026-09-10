import 'package:flutter/material.dart';
import 'package:dafter/core/utils/id_generator.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_item.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/purchases/service/purchase_service.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';

class PurchaseInvoiceScreen extends StatefulWidget {
  const PurchaseInvoiceScreen({super.key});
  @override
  State<PurchaseInvoiceScreen> createState() => _PurchaseInvoiceScreenState();
}

class _PurchaseInvoiceScreenState extends State<PurchaseInvoiceScreen> {
  final _supplierRepository = SupplierRepository();
  final _productRepository = ProductRepository();
  final _accountRepository = AccountRepository();
  final _purchaseService = PurchaseService();
  final _paidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  Supplier? _supplier;
  Account? _account;
  final List<_Line> _items = [];
  String _paymentType = 'نقدي';
  bool _saving = false;

  double get _subtotal => _items.fold(0, (s, i) => s + i.total);
  double get _paid => double.tryParse(_paidController.text.trim()) ?? 0;
  double get _remaining => (_subtotal - _paid).clamp(0, double.infinity).toDouble();

  @override
  void initState() { super.initState(); _paidController.addListener(_refresh); }
  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { _paidController.dispose(); _notesController.dispose(); super.dispose(); }

  Future<void> _selectSupplier() async {
    final suppliers = await _supplierRepository.getSuppliers();
    if (!mounted) return;
    if (suppliers.isEmpty) { _message('لا يوجد موردين. أضف مورد أولاً.'); return; }
    final selected = await showDialog<Supplier>(context: context, builder: (_) => AlertDialog(
      title: const Text('اختيار المورد'),
      content: SizedBox(width: 500, height: 420, child: ListView.builder(itemCount: suppliers.length, itemBuilder: (_, i) {
        final s = suppliers[i];
        return ListTile(title: Text(s.name), subtitle: Text(s.phone ?? 'بدون رقم هاتف'), trailing: Text('${s.balance.toStringAsFixed(2)} ج.م'), onTap: () => Navigator.pop(context, s));
      })),
    ));
    if (selected != null && mounted) setState(() => _supplier = selected);
  }

  Future<void> _selectAccount() async {
    final accounts = await _accountRepository.getAccounts();
    if (!mounted) return;
    if (accounts.isEmpty) { _message('لا يوجد حسابات. أضف حساب أولاً.'); return; }
    final selected = await showDialog<Account>(context: context, builder: (_) => AlertDialog(
      title: const Text('اختيار الحساب'),
      content: SizedBox(width: 500, height: 420, child: ListView.builder(itemCount: accounts.length, itemBuilder: (_, i) {
        final a = accounts[i];
        return ListTile(title: Text(a.name), subtitle: Text('${a.balance.toStringAsFixed(2)} ج.م'), onTap: () => Navigator.pop(context, a));
      })),
    ));
    if (selected != null && mounted) setState(() => _account = selected);
  }

  Future<void> _addItem() async {
    final products = await _productRepository.getProducts();
    if (!mounted) return;
    if (products.isEmpty) { _message('لا يوجد منتجات. أضف منتج أولاً.'); return; }
    final product = await showDialog<Product>(context: context, builder: (_) => AlertDialog(
      title: const Text('اختيار المنتج'),
      content: SizedBox(width: 550, height: 450, child: ListView.builder(itemCount: products.length, itemBuilder: (_, i) {
        final p = products[i];
        return ListTile(title: Text(p.name), subtitle: Text('المخزون الحالي: ${p.quantity}'), trailing: Text('${p.purchasePrice.toStringAsFixed(2)} ج.م'), onTap: () => Navigator.pop(context, p));
      })),
    ));
    if (product == null || !mounted) return;
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: product.purchasePrice.toStringAsFixed(2));
    final result = await showDialog<_Line>(context: context, builder: (_) => AlertDialog(
      title: Text(product.name),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية')),
        const SizedBox(height: 12),
        TextField(controller: priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر الشراء')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () {
        final q = int.tryParse(quantityController.text.trim());
        final price = double.tryParse(priceController.text.trim());
        if (q == null || q <= 0 || price == null || !price.isFinite || price < 0) return;
        Navigator.pop(context, _Line(product: product, quantity: q, price: price));
      }, child: const Text('إضافة'))],
    ));
    quantityController.dispose(); priceController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final index = _items.indexWhere((x) => x.product.id == result.product.id);
      if (index >= 0) { _items[index].quantity += result.quantity; _items[index].price = result.price; }
      else { _items.add(result); }
      if (_paymentType == 'نقدي') _paidController.text = _subtotal.toStringAsFixed(2);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_supplier == null) { _message('من فضلك اختر المورد'); return; }
    if (_items.isEmpty) { _message('أضف صنف واحد على الأقل'); return; }
    if (!_paid.isFinite || _paid < 0 || _paid > _subtotal) { _message('المبلغ المدفوع غير صحيح'); return; }
    if (_paid > 0 && _account == null) { _message('اختر الحساب الذي تم الدفع منه'); return; }
    setState(() => _saving = true);
    try {
      final purchaseId = IdGenerator.generate();
      final purchase = Purchase(id: purchaseId, supplierId: _supplier!.id, date: DateTime.now(), items: _items.asMap().entries.map((e) => PurchaseItem(id: '${purchaseId}_${e.key}', purchaseId: purchaseId, productId: e.value.product.id, quantity: e.value.quantity, price: e.value.price, discount: 0)).toList(), discount: 0, paidAmount: _paid, notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim());
      await _purchaseService.createPurchase(purchase: purchase, accountId: _account?.id);
      if (!mounted) return;
      _message('تم حفظ فاتورة الشراء بنجاح');
      Navigator.pop(context, true);
    } catch (e) { if (mounted) _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: const Color(0xFFF7F8F9), appBar: AppBar(title: const Text('فاتورة شراء جديدة'), backgroundColor: Colors.white, surfaceTintColor: Colors.white), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _card('بيانات المورد', InkWell(onTap: _selectSupplier, child: InputDecorator(decoration: const InputDecoration(labelText: 'المورد', prefixIcon: Icon(Icons.store_outlined), border: OutlineInputBorder()), child: Text(_supplier?.name ?? 'اختر المورد')))),
    const SizedBox(height: 16),
    _card('أصناف الفاتورة', Column(children: [Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('إضافة صنف'))), const SizedBox(height: 12), if (_items.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('لم تتم إضافة أصناف')) else ..._items.asMap().entries.map((e) => ListTile(contentPadding: EdgeInsets.zero, title: Text(e.value.product.name), subtitle: Text('${e.value.quantity} × ${e.value.price.toStringAsFixed(2)} ج.م'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${e.value.total.toStringAsFixed(2)} ج.م'), IconButton(onPressed: () => setState(() => _items.removeAt(e.key)), icon: const Icon(Icons.delete_outline, color: Colors.red))]))])),
    const SizedBox(height: 16),
    _card('الدفع', Column(children: [DropdownButtonFormField<String>(initialValue: _paymentType, decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'نقدي', child: Text('نقدي')), DropdownMenuItem(value: 'آجل', child: Text('آجل'))], onChanged: (v) { if (v == null) return; setState(() { _paymentType = v; _paidController.text = v == 'نقدي' ? _subtotal.toStringAsFixed(2) : '0'; }); }), const SizedBox(height: 12), TextFormField(controller: _paidController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المدفوع', border: OutlineInputBorder())), const SizedBox(height: 12), if (_paid > 0) InkWell(onTap: _selectAccount, child: InputDecorator(decoration: const InputDecoration(labelText: 'الحساب', prefixIcon: Icon(Icons.account_balance_wallet_outlined), border: OutlineInputBorder()), child: Text(_account?.name ?? 'اختر الحساب'))), const SizedBox(height: 12), TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder()))])),
    const SizedBox(height: 16),
    _card('ملخص', Row(children: [Expanded(child: Text('الإجمالي: ${_subtotal.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), Text('المتبقي: ${_remaining.toStringAsFixed(2)} ج.م')]))),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الفاتورة'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
  ])));

  Widget _card(String title, Widget child) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 14), child]));
}

class _Line {
  final Product product;
  int quantity;
  double price;
  _Line({required this.product, required this.quantity, required this.price});
  double get total => quantity * price;
}
