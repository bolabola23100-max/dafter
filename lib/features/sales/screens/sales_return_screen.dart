import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_item.dart';
import 'package:dafter/features/model/sale_return.dart';
import 'package:dafter/features/sales/repo/sales_repository.dart';
import 'package:dafter/features/sales/service/sale_return_service.dart';
import 'package:flutter/material.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final SalesRepository _salesRepository = SalesRepository();
  final ProductRepository _productRepository = ProductRepository();
  final AccountRepository _accountRepository = AccountRepository();
  final SaleReturnService _service = SaleReturnService();

  final _refundController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  List<Sale> _sales = [];
  List<Account> _accounts = [];
  Map<String, Product> _products = {};
  Sale? _selectedSale;
  Account? _selectedAccount;
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _refundController.dispose();
    _notesController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _salesRepository.getSales(),
        _accountRepository.getAccounts(),
        _productRepository.getProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = results[0] as List<Sale>;
        _accounts = results[1] as List<Account>;
        final products = results[2] as List<Product>;
        _products = {for (final product in products) product.id: product};
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _message('حصلت مشكلة وأنا بجيب الفواتير');
    }
  }

  void _selectSale(Sale? sale) {
    for (final controller in _quantityControllers.values) controller.dispose();
    _quantityControllers.clear();
    if (sale != null) {
      for (final item in sale.items) {
        _quantityControllers[item.id] = TextEditingController(text: '0');
      }
    }
    setState(() {
      _selectedSale = sale;
      _selectedAccount = null;
      _refundController.text = '0';
    });
  }

  double _effectiveUnitPrice(SaleItem item) {
    if (item.quantity <= 0) return item.price;
    return item.subtotal / item.quantity;
  }

  double _returnTotal() {
    final sale = _selectedSale;
    if (sale == null) return 0;
    double total = 0;
    for (final item in sale.items) {
      final quantity = int.tryParse(_quantityControllers[item.id]?.text.trim() ?? '') ?? 0;
      total += quantity * _effectiveUnitPrice(item);
    }
    return total;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final sale = _selectedSale;
    if (sale == null) {
      _message('اختار فاتورة البيع الأول');
      return;
    }

    final returnId = _id();
    final returnItems = <SaleReturnItem>[];
    for (final item in sale.items) {
      final quantity = int.tryParse(_quantityControllers[item.id]?.text.trim() ?? '') ?? 0;
      if (quantity < 0) {
        _message('الكمية لازم تكون صفر أو أكتر');
        return;
      }
      if (quantity > 0) {
        returnItems.add(
          SaleReturnItem(
            id: _id(),
            returnId: returnId,
            saleItemId: item.id,
            productId: item.productId,
            quantity: quantity,
            price: _effectiveUnitPrice(item),
          ),
        );
      }
    }

    if (returnItems.isEmpty) {
      _message('حدد كمية من صنف واحد على الأقل');
      return;
    }

    final total = returnItems.fold<double>(0, (sum, item) => sum + item.total);
    final refund = double.tryParse(_refundController.text.trim()) ?? -1;
    if (refund < 0 || refund > total) {
      _message('المبلغ اللي هيرجع للعميل لازم يكون بين صفر وقيمة المرتجع');
      return;
    }
    if (refund > 0 && _selectedAccount == null) {
      _message('اختار الحساب اللي هتطلع منه الفلوس');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.createReturn(
        saleReturn: SaleReturn(
          id: returnId,
          saleId: sale.id,
          customerId: sale.customerId,
          date: DateTime.now(),
          items: returnItems,
          refundedAmount: refund,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
        accountId: _selectedAccount?.id,
      );
      if (!mounted) return;
      _message('المرتجع اتحفظ والمخزون والأرصدة اتحدثت');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  String _saleLabel(Sale sale) {
    final date = '${sale.date.day}/${sale.date.month}/${sale.date.year}';
    return 'فاتورة ${sale.id} — $date — ${sale.total.toStringAsFixed(2)} جنيه';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9),
      appBar: AppBar(title: const Text('مرتجع بيع'), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _card(
                        title: 'الفاتورة الأصلية',
                        child: DropdownButtonFormField<Sale>(
                          initialValue: _selectedSale,
                          isExpanded: true,
                          decoration: _decoration('اختار الفاتورة'),
                          items: _sales.map((sale) => DropdownMenuItem<Sale>(value: sale, child: Text(_saleLabel(sale)))).toList(),
                          onChanged: _selectSale,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedSale != null) ...[
                        _buildItemsCard(_selectedSale!),
                        const SizedBox(height: 16),
                        _card(
                          title: 'فلوس المرتجع',
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _refundController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: _decoration('المبلغ اللي هيرجع للعميل').copyWith(suffixText: 'جنيه'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<Account>(
                                  initialValue: _selectedAccount,
                                  isExpanded: true,
                                  decoration: _decoration('الحساب اللي هتطلع منه الفلوس'),
                                  items: _accounts.map((account) => DropdownMenuItem<Account>(value: account, child: Text('${account.name} — ${account.balance.toStringAsFixed(2)} جنيه'))).toList(),
                                  onChanged: (double.tryParse(_refundController.text.trim()) ?? 0) > 0 ? (value) => setState(() => _selectedAccount = value) : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          title: 'ملاحظات',
                          child: TextField(controller: _notesController, maxLines: 3, decoration: _decoration('ملاحظات اختيارية')),
                        ),
                        const SizedBox(height: 16),
                        _summaryCard(),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? 'بيحفظ...' : 'حفظ المرتجع'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50)),
                          ),
                        ),
                      ] else
                        _emptyState(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildItemsCard(Sale sale) {
    return _card(
      title: 'الأصناف',
      child: Column(
        children: sale.items.map((item) {
          final product = _products[item.productId];
          final controller = _quantityControllers[item.id]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text(product?.name ?? 'منتج مش موجود')),
                Expanded(child: Text('اتباع: ${item.quantity}')),
                Expanded(child: Text('${_effectiveUnitPrice(item).toStringAsFixed(2)} جنيه')),
                SizedBox(width: 130, child: TextField(controller: controller, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: _decoration('المرتجع'))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _summaryCard() {
    final total = _returnTotal();
    final refund = double.tryParse(_refundController.text.trim()) ?? 0;
    final credit = (total - refund).clamp(0, double.infinity).toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
      child: Row(children: [Expanded(child: _summary('قيمة المرتجع', total)), Expanded(child: _summary('فلوس راجعة', refund)), Expanded(child: _summary('هيتخصم من حساب العميل', credit))]),
    );
  }

  Widget _summary(String label, double value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 6), Text('${value.toStringAsFixed(2)} جنيه', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]);

  Widget _emptyState() => _card(title: 'مفيش فاتورة مختارة', child: const Padding(padding: EdgeInsets.all(25), child: Text('اختار فاتورة بيع عشان تحدد الأصناف والكميات اللي هترجع.')));

  Widget _card({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 18), child]),
      );

  InputDecoration _decoration(String label) => InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)));
}
