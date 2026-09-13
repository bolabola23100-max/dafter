import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/model/customer.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_return.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/sales/repo/sale_return_repository.dart';
import 'package:dafter/features/sales/repo/sales_repository.dart';
import 'package:flutter/material.dart';

class CustomerStatementScreen extends StatefulWidget {
  final String? customerId;
  const CustomerStatementScreen({super.key, this.customerId});
  @override
  State<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  final _customerRepository = CustomerRepository();
  final _salesRepository = SalesRepository();
  final _saleReturnRepository = SaleReturnRepository();
  final _paymentRepository = PaymentRepository();
  final _productRepository = ProductRepository();

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<Sale> _sales = [];
  List<SaleReturn> _returns = [];
  List<Payment> _payments = [];
  Map<String, Product> _products = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final results = await Future.wait([
        _customerRepository.getCustomers(),
        _productRepository.getProducts(),
      ]);
      final customers = results[0] as List<Customer>;
      final products = results[1] as List<Product>;
      if (!mounted) return;
      Customer? selected;
      if (widget.customerId != null) {
        for (final customer in customers) {
          if (customer.id == widget.customerId) {
            selected = customer;
            break;
          }
        }
      }
      setState(() {
        _customers = customers;
        _selectedCustomer = selected;
        _products = {for (final product in products) product.id: product};
        _isLoading = false;
      });
      if (selected != null) await _loadStatement(selected.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('مش قادر أجيب بيانات العميل: $e');
    }
  }

  Future<void> _loadStatement(String customerId) async {
    try {
      final results = await Future.wait([
        _salesRepository.getSalesByCustomer(customerId),
        _saleReturnRepository.getReturns(),
        _paymentRepository.getPaymentsByPerson(customerId),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = results[0] as List<Sale>;
        _returns = (results[1] as List<SaleReturn>)
            .where((saleReturn) => saleReturn.customerId == customerId)
            .toList();
        _payments = (results[2] as List<Payment>)
            .where((payment) => payment.type == PaymentType.receipt)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('مش قادر أجيب كشف الحساب: $e');
    }
  }

  void _onCustomerChanged(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
      _sales = [];
      _returns = [];
      _payments = [];
    });
    if (customer != null) _loadStatement(customer.id);
  }

  double get _totalSales => _sales.fold(0, (sum, sale) => sum + sale.total);
  double get _totalSalesRemaining => _sales.fold(
        0,
        (sum, sale) =>
            sum + sale.remainingAmount.clamp(0, double.infinity).toDouble(),
      );
  double get _totalReturns => _returns.fold(0, (sum, saleReturn) => sum + saleReturn.total);
  double get _totalReturnCredits => _returns.fold(
        0,
        (sum, saleReturn) =>
            sum + (saleReturn.total - saleReturn.refundedAmount).clamp(0.0, double.infinity).toDouble(),
      );
  double get _totalReceipts => _payments.fold(0, (sum, payment) => sum + payment.amount);

  double get _calculatedBalance {
    final customer = _selectedCustomer;
    if (customer == null) return 0;
    return customer.openingBalance +
        _totalSalesRemaining -
        _totalReturnCredits -
        _totalReceipts;
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';
  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final customer = _selectedCustomer;
    final balance = customer == null ? 0.0 : _calculatedBalance;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        body: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E9EB))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 21),
                  ),
                  const SizedBox(width: 10),
                  const Text('كشف حساب عميل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCustomerSelector(),
                              const SizedBox(height: 16),
                              if (customer == null)
                                _buildEmptyState()
                              else ...[
                                _buildSummary(customer, balance),
                                const SizedBox(height: 16),
                                _buildTransactions(),
                              ],
                            ],
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

  Widget _buildCustomerSelector() {
    return _Card(
      child: DropdownButtonFormField<Customer>(
        initialValue: _selectedCustomer,
        decoration: const InputDecoration(labelText: 'العميل', border: OutlineInputBorder()),
        hint: const Text('اختار العميل'),
        items: _customers
            .map((customer) => DropdownMenuItem<Customer>(value: customer, child: Text(customer.name)))
            .toList(),
        onChanged: _onCustomerChanged,
      ),
    );
  }

  Widget _buildSummary(Customer customer, double balance) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(title: 'رصيد قبل كده', value: _money(customer.openingBalance)),
        _SummaryCard(title: 'إجمالي المبيعات', value: _money(_totalSales)),
        _SummaryCard(title: 'إجمالي المرتجعات', value: _money(_totalReturns)),
        _SummaryCard(title: 'إجمالي اللي اتدفع', value: _money(_totalReceipts)),
        _SummaryCard(title: 'عليه دلوقتي', value: _money(balance)),
      ],
    );
  }

  Widget _buildTransactions() {
    final rows = <Widget>[];
    for (final sale in _sales) {
      rows.add(_buildSaleTile(sale));
    }
    for (final saleReturn in _returns) {
      final credit = (saleReturn.total - saleReturn.refundedAmount).clamp(0.0, double.infinity).toDouble();
      rows.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.assignment_return_outlined),
          title: Text('مرتجع بيع — ${_money(saleReturn.total)}'),
          subtitle: Text('${_date(saleReturn.date)} — ${credit > 0 ? 'خصم من رصيد العميل ${_money(credit)}' : 'تم رد الفلوس بالكامل'}'),
          trailing: credit > 0 ? Text('+${_money(credit)}', style: const TextStyle(fontWeight: FontWeight.bold)) : null,
        ),
      );
    }
    for (final payment in _payments) {
      rows.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.payments_outlined),
          title: const Text('إيصال تحصيل من العميل'),
          subtitle: Text('${_date(payment.date)}${payment.notes == null || payment.notes!.trim().isEmpty ? '' : ' — ${payment.notes}'}'),
          trailing: Text('+${_money(payment.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('الفواتير والحركات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لسه مفيش حركات على الحساب')))
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _buildSaleTile(Sale sale) {
    final saleReturns = _returns.where((item) => item.saleId == sale.id).toList();
    final returnedByItem = <String, int>{};
    for (final saleReturn in saleReturns) {
      for (final item in saleReturn.items) {
        returnedByItem.update(item.saleItemId, (value) => value + item.quantity, ifAbsent: () => item.quantity);
      }
    }
    final returnTotal = saleReturns.fold<double>(0, (sum, saleReturn) => sum + saleReturn.total);
    final refundedTotal = saleReturns.fold<double>(0, (sum, saleReturn) => sum + saleReturn.refundedAmount);
    final remaining = sale.remainingAmount.clamp(0, double.infinity).toDouble();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(sale.displayInvoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_date(sale.date)} • ${_money(sale.total)} • مدفوع ${_money(sale.paidAmount)}${remaining > 0 ? ' • باقي ${_money(remaining)}' : ''}'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          const Divider(),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('الأصناف اللي اشتراها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 8),
          ...sale.items.map((item) {
            final returned = returnedByItem[item.id] ?? 0;
            final productName = _products[item.productId]?.name ?? item.productId;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(productName),
              subtitle: Text('الكمية: ${item.quantity} • السعر: ${_money(item.price)} • إجمالي: ${_money(item.subtotal)}${returned > 0 ? ' • مرتجع: $returned' : ''}'),
            );
          }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('المدفوع وقت البيع: ${_money(sale.paidAmount)} • الآجل من الفاتورة: ${_money(remaining)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (returnTotal > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('المرتجع: ${_money(returnTotal)} • المردود نقدًا: ${_money(refundedTotal)}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(_customers.isEmpty ? 'لسه مفيش عملاء' : 'اختار العميل عشان تشوف فواتيره والمشتريات والتحصيلات'),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const _SummaryCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
