import 'package:flutter/material.dart';
import 'package:dafter/core/widgets/custom_text_form_field.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/purchase_return.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/repo/purchase_return_repository.dart';
import 'package:dafter/features/purchases/service/purchase_return_service.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';

class PurchaseReturnScreen extends StatefulWidget {
  final String? purchaseId;
  const PurchaseReturnScreen({super.key, this.purchaseId});
  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  final _notesController = TextEditingController();
  final _purchaseRepository = PurchaseRepository();
  final _productRepository = ProductRepository();
  final _supplierRepository = SupplierRepository();
  final _accountRepository = AccountRepository();
  final _returnRepository = PurchaseReturnRepository();
  final _returnService = PurchaseReturnService();
  Purchase? _purchase;
  String? _supplierName;
  List<Account> _accounts = [];
  Account? _refundAccount;
  List<ReturnItem> _items = [];
  double _refundedAmount = 0;
  bool _loading = false;
  bool _saving = false;

  double get _total => _items.fold(0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    if (widget.purchaseId != null) WidgetsBinding.instance.addPostFrameCallback((_) => _loadPurchase(widget.purchaseId!));
  }

  @override
  void dispose() { _notesController.dispose(); super.dispose(); }

  Future<void> _loadAccounts() async {
    try { final a = await _accountRepository.getAccounts(); if (mounted) setState(() => _accounts = a); }
    catch (_) { if (mounted) _message('حصلت مشكلة وأنا بجيب الحسابات'); }
  }

  Future<void> _choosePurchase() async {
    final purchases = await _purchaseRepository.getPurchases();
    if (!mounted) return;
    if (purchases.isEmpty) { _message('مفيش فواتير شراء متاحة للمرتجع'); return; }
    final selected = await showDialog<Purchase>(context: context, builder: (_) => AlertDialog(
      title: const Text('اختار فاتورة الشراء'),
      content: SizedBox(width: 650, height: 500, child: ListView.separated(itemCount: purchases.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, i) {
        final p = purchases[i];
        return ListTile(
          title: Text('فاتورة #${p.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('التاريخ: ${_date(p.date)}  •  ${p.items.length} أصناف'),
          trailing: Text('${p.total.toStringAsFixed(2)} ج.م'),
          onTap: () => Navigator.pop(context, p),
        );
      })),
    ));
    if (selected != null) await _loadPurchase(selected.id);
  }

  Future<void> _loadPurchase(String id) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final purchase = await _purchaseRepository.getPurchaseById(id);
      if (!mounted) return;
      if (purchase == null) { _message('فاتورة الشراء مش موجودة'); return; }
      String? supplier;
      if (purchase.supplierId != null) supplier = (await _supplierRepository.getSupplierById(purchase.supplierId!))?.name;
      final returned = await _getAlreadyReturnedQuantities(purchase.id);
      final loaded = <ReturnItem>[];
      for (final item in purchase.items) {
        final product = await _productRepository.getProductById(item.productId);
        if (product == null) continue;
        final remaining = item.quantity - (returned[item.id] ?? 0);
        if (remaining > 0) loaded.add(ReturnItem(purchaseItemId: item.id, productId: item.productId, name: product.name, price: item.price, maxQuantity: remaining, quantity: 0));
      }
      setState(() { _purchase = purchase; _supplierName = supplier; _items = loaded; _refundedAmount = 0; _refundAccount = null; });
    } catch (e) { if (mounted) _message('حصلت مشكلة وأنا بجيب الفاتورة: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<Map<String, int>> _getAlreadyReturnedQuantities(String purchaseId) async {
    final returns = await _returnRepository.getReturnsByPurchase(purchaseId);
    final result = <String, int>{};
    for (final r in returns) for (final item in r.items) result.update(item.purchaseItemId, (v) => v + item.quantity, ifAbsent: () => item.quantity);
    return result;
  }

  void _setQuantity(ReturnItem item, int quantity) {
    final index = _items.indexOf(item);
    if (index < 0) return;
    setState(() => _items[index] = item.copyWith(quantity: quantity.clamp(0, item.maxQuantity)));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_purchase == null) { _message('اختار فاتورة الشراء الأول'); return; }
    final selected = _items.where((i) => i.quantity > 0).toList();
    if (selected.isEmpty) { _message('اختار صنف وكمية للمرتجع'); return; }
    if (!_refundedAmount.isFinite || _refundedAmount < 0 || _refundedAmount > _total) { _message('راجع مبلغ الفلوس الراجعة'); return; }
    if (_refundedAmount > 0 && _refundAccount == null) { _message('اختار الحساب اللي الفلوس هتنزل فيه'); return; }
    setState(() => _saving = true);
    try {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final returnItems = selected.map((item) => PurchaseReturnItem(id: '${id}_${item.purchaseItemId}', returnId: id, purchaseItemId: item.purchaseItemId, productId: item.productId, quantity: item.quantity, price: item.price)).toList();
      await _returnService.createReturn(purchaseId: _purchase!.id, items: returnItems, refundedAmount: _refundedAmount, refundAccountId: _refundAccount?.id, notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim());
      if (!mounted) return;
      _message('المرتجع اتحفظ والمخزون اتحدث');
      Navigator.pop(context, true);
    } catch (e) { if (mounted) _message(e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: const Color(0xFFF7F8F9), appBar: AppBar(title: const Text('مرتجع شراء'), backgroundColor: Colors.white, surfaceTintColor: Colors.white), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _card('الفاتورة الأصلية', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text(_purchase == null ? 'لم يتم اختيار فاتورة' : 'فاتورة #${_purchase!.id}', style: const TextStyle(fontWeight: FontWeight.bold))), FilledButton.icon(onPressed: _loading ? null : _choosePurchase, icon: const Icon(Icons.search), label: const Text('اختيار فاتورة'))]), if (_purchase != null) ...[const SizedBox(height: 8), Text('المورد: ${_supplierName ?? 'بدون مورد'}'), Text('إجمالي الفاتورة: ${_purchase!.total.toStringAsFixed(2)} ج.م')]])),
    const SizedBox(height: 16),
    _card('الأصناف', _purchase == null ? const Padding(padding: EdgeInsets.all(30), child: Text('اختار فاتورة الشراء الأول', textAlign: TextAlign.center)) : _items.isEmpty ? const Padding(padding: EdgeInsets.all(30), child: Text('كل أصناف الفاتورة دي اتعمل لها مرتجع قبل كده', textAlign: TextAlign.center)) : Column(children: _items.map((item) => Row(children: [Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))), Text('${item.price.toStringAsFixed(2)} ج.م'), const SizedBox(width: 15), IconButton(onPressed: item.quantity == 0 ? null : () => _setQuantity(item, item.quantity - 1), icon: const Icon(Icons.remove_circle_outline)), SizedBox(width: 35, child: Text('${item.quantity}', textAlign: TextAlign.center)), IconButton(onPressed: item.quantity >= item.maxQuantity ? null : () => _setQuantity(item, item.quantity + 1), icon: const Icon(Icons.add_circle_outline)), SizedBox(width: 110, child: Text('${item.total.toStringAsFixed(2)} ج.م', textAlign: TextAlign.end)), const SizedBox(height: 48)])).toList())),
    const SizedBox(height: 16),
    _card('الاسترداد والملاحظات', Column(children: [CustomTextFormField(keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ اللي المورد رجعهولك', hintText: '0 لو هيتخصم من حساب المورد'), onChanged: (v) => setState(() => _refundedAmount = double.tryParse(v) ?? 0)), if (_refundedAmount > 0) ...[const SizedBox(height: 12), DropdownButtonFormField<Account>(initialValue: _refundAccount, decoration: const InputDecoration(labelText: 'الحساب اللي الفلوس هتنزل فيه', border: OutlineInputBorder()), items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text('${a.name} - ${a.balance.toStringAsFixed(2)} ج.م'))).toList(), onChanged: (v) => setState(() => _refundAccount = v))], const SizedBox(height: 12), CustomTextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'))])),
    const SizedBox(height: 16),
    _card('إجمالي المرتجع', Row(children: [const Text('قيمة الأصناف المرتجعة'), const Spacer(), Text('${_total.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
    const SizedBox(height: 20),
    FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.assignment_return_outlined), label: Text(_saving ? 'بيحفظ...' : 'حفظ المرتجع'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
  ])));

  Widget _card(String title, Widget child) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 14), child]));
  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class ReturnItem {
  final String purchaseItemId;
  final String productId;
  final String name;
  final double price;
  final int maxQuantity;
  final int quantity;
  const ReturnItem({required this.purchaseItemId, required this.productId, required this.name, required this.price, required this.maxQuantity, required this.quantity});
  double get total => price * quantity;
  ReturnItem copyWith({int? quantity}) => ReturnItem(purchaseItemId: purchaseItemId, productId: productId, name: name, price: price, maxQuantity: maxQuantity, quantity: quantity ?? this.quantity);
}
