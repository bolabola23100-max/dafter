import 'package:flutter/material.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/accounts/repo/account_repository.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/model/account.dart';
import 'package:dafter/features/model/customer.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_item.dart';
import 'package:dafter/features/sales/service/sales_service.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');
  final _paidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final _productRepository = ProductRepository();
  final _customerRepository = CustomerRepository();
  final _accountRepository = AccountRepository();
  final _salesService = SalesService();

  List<Product> _products = [];
  List<Customer> _customers = [];
  List<Account> _accounts = [];
  final List<_SaleLine> _items = [];
  Customer? _selectedCustomer;
  Account? _selectedAccount;
  String _paymentType = 'نقدي';
  bool _loading = true;
  bool _saving = false;

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;
  double get _total => (_subtotal - _discount).clamp(0, double.infinity).toDouble();
  double get _paid => double.tryParse(_paidController.text.trim()) ?? 0;
  double get _remaining => (_total - _paid).clamp(0, double.infinity).toDouble();

  @override
  void initState() {
    super.initState();
    _loadData();
    _discountController.addListener(_refresh);
    _paidController.addListener(_refresh);
  }

  Future<void> _loadData() async {
    try {
      final products = await _productRepository.getProducts();
      final customers = await _customerRepository.getCustomers();
      final accounts = await _accountRepository.getAccounts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _customers = customers;
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _addProduct(Product product) {
    final existing = _items.where((item) => item.product.id == product.id).firstOrNull;
    if (existing != null) {
      if (existing.quantity < product.quantity) {
        setState(() => existing.quantity++);
      }
      return;
    }
    if (product.quantity <= 0) {
      _showError('المنتج ده مفيش منه كمية في المخزن');
      return;
    }
    setState(() => _items.add(_SaleLine(product: product, quantity: 1, price: product.sellingPrice)));
  }

  void _setPaymentType(String? value) {
    if (value == null) return;
    setState(() {
      _paymentType = value;
      if (value == 'آجل') {
        _paidController.text = '0';
      } else if (value == 'نقدي') {
        _paidController.text = _total.toStringAsFixed(2);
      } else if (_paid > _total) {
        _paidController.text = _total.toStringAsFixed(2);
      }
    });
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      _showError('ضيف صنف واحد على الأقل للفاتورة');
      return;
    }
    if (_paid < 0 || _paid > _total) {
      _showError('المدفوع مينفعش يكون أكبر من إجمالي الفاتورة');
      return;
    }
    if (_paid > 0 && _selectedAccount == null) {
      _showError('اختار الحساب اللي دخلت فيه الفلوس');
      return;
    }
    if (_paymentType == 'آجل' && _selectedCustomer == null) {
      _showError('الفاتورة الآجلة لازم تتسجل على عميل');
      return;
    }

    setState(() => _saving = true);
    try {
      final saleId = DateTime.now().microsecondsSinceEpoch.toString();
      final sale = Sale(
        id: saleId,
        customerId: _selectedCustomer?.id,
        date: DateTime.now(),
        items: _items
            .map((line) => SaleItem(
                  id: '${saleId}_${line.product.id}',
                  saleId: saleId,
                  productId: line.product.id,
                  quantity: line.quantity,
                  price: line.price,
                ))
            .toList(),
        discount: _discount,
        paidAmount: _paid,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await _salesService.createSale(sale: sale, accountId: _selectedAccount?.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الفاتورة اتحفظت واتخصمت من المخزن')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _discountController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        body: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1150),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _customerCard(),
                                const SizedBox(height: 16),
                                _itemsCard(),
                                const SizedBox(height: 16),
                                _paymentCard(),
                                const SizedBox(height: 16),
                                _bottomBar(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5E9EB)))),
        child: Row(
          children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
            const SizedBox(width: 10),
            const Text('فاتورة بيع جديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text('إلغاء')),
          ],
        ),
      );

  Widget _customerCard() => _SectionCard(
        title: 'العميل',
        icon: Icons.person_outline,
        child: DropdownButtonFormField<Customer?>(
          initialValue: _selectedCustomer,
          decoration: _decoration('العميل (اختياري)'),
          hint: const Text('سيبها فاضية لو البيع نقدي'),
          items: [
            const DropdownMenuItem<Customer?>(value: null, child: Text('عميل نقدي')),
            ..._customers.map((customer) => DropdownMenuItem<Customer?>(value: customer, child: Text(customer.name))),
          ],
          onChanged: (value) => setState(() => _selectedCustomer = value),
        ),
      );

  Widget _itemsCard() => _SectionCard(
        title: 'الأصناف',
        icon: Icons.inventory_2_outlined,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Product>(
                    decoration: _decoration('اختار منتج'),
                    hint: const Text('اختار المنتج لإضافته'),
                    items: _products.map((product) => DropdownMenuItem<Product>(
                      value: product,
                      child: Text('${product.name} — ${product.quantity} قطعة'),
                    )).toList(),
                    onChanged: (product) {
                      if (product != null) _addProduct(product);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_items.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Text('لسه مفيش أصناف في الفاتورة'))
            else
              ..._items.asMap().entries.map((entry) => _lineRow(entry.key, entry.value)),
          ],
        ),
      );

  Widget _lineRow(int index, _SaleLine line) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            SizedBox(
              width: 120,
              child: TextFormField(
                initialValue: line.quantity.toString(),
                keyboardType: TextInputType.number,
                decoration: _decoration('الكمية'),
                onChanged: (value) {
                  final quantity = int.tryParse(value) ?? 0;
                  if (quantity >= 1 && quantity <= line.product.quantity) {
                    setState(() => line.quantity = quantity);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: TextFormField(
                initialValue: line.price.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration('سعر البيع'),
                onChanged: (value) => setState(() => line.price = double.tryParse(value) ?? line.price),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(width: 110, child: Text('${line.subtotal.toStringAsFixed(2)} جنيه', textAlign: TextAlign.center)),
            IconButton(onPressed: () => setState(() => _items.removeAt(index)), icon: const Icon(Icons.delete_outline)),
          ],
        ),
      );

  Widget _paymentCard() => _SectionCard(
        title: 'الحساب والدفع',
        icon: Icons.payments_outlined,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _numberField(_discountController, 'الخصم')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_paidController, 'المدفوع')),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: _paymentType,
                  decoration: _decoration('نوع الدفع'),
                  items: const ['نقدي', 'جزئي', 'آجل'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: _setPaymentType,
                )),
              ],
            ),
            if (_paid > 0) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Account>(
                initialValue: _selectedAccount,
                decoration: _decoration('الحساب اللي دخلت فيه الفلوس'),
                hint: const Text('اختار الصندوق أو البنك'),
                items: _accounts.map((account) => DropdownMenuItem<Account>(
                  value: account,
                  child: Text('${account.name} — ${account.balance.toStringAsFixed(2)} جنيه'),
                )).toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(controller: _notesController, maxLines: 2, decoration: _decoration('ملاحظات')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _summary('الإجمالي', _total)),
                Expanded(child: _summary('المدفوع', _paid)),
                Expanded(child: _summary('الباقي', _remaining)),
              ],
            ),
          ],
        ),
      );

  Widget _numberField(TextEditingController controller, String label) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decoration(label),
      );

  Widget _summary(String title, double value) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E9EB)), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [Text(title), const SizedBox(height: 5), Text('${value.toStringAsFixed(2)} جنيه', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
      );

  Widget _bottomBar() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveInvoice,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'بيتحفظ...' : 'حفظ الفاتورة'),
          ),
        ],
      );

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFFE5E9EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: Color(0xFFE5E9EB))),
      );
}

class _SaleLine {
  final Product product;
  int quantity;
  double price;

  _SaleLine({required this.product, required this.quantity, required this.price});

  double get subtotal => quantity * price;
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 19, color: const Color(0xFF0E4C4C)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 18),
          child,
        ]),
      );
}
