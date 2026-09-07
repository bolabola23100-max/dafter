import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/accounts/repo/payment_repository.dart';
import 'package:dafter/features/model/customer.dart';
import 'package:dafter/features/model/payment.dart';
import 'package:dafter/features/model/sale.dart';
import 'package:dafter/features/model/sale_return.dart';
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

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<Sale> _sales = [];
  List<SaleReturn> _returns = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _customerRepository.getCustomers();
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
        _isLoading = false;
      });

      if (selected != null) {
        await _loadStatement(selected.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('مش قادر أجيب العملاء: $e');
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

    if (customer != null) {
      _loadStatement(customer.id);
    }
  }

  double get _totalSales => _sales.fold(0, (sum, sale) => sum + sale.total);

  double get _totalSalesRemaining =>
      _sales.fold(0, (sum, sale) => sum + sale.remainingAmount);

  double get _totalReturns => _returns.fold(0, (sum, saleReturn) => sum + saleReturn.total);

  double get _totalReturnCredits => _returns.fold(
        0,
        (sum, saleReturn) =>
            sum + (saleReturn.total - saleReturn.refundedAmount).clamp(0.0, double.infinity),
      );

  double get _totalReceipts =>
      _payments.fold(0, (sum, payment) => sum + payment.amount);

  double get _calculatedBalance {
    final customer = _selectedCustomer;
    if (customer == null) return 0;

    return customer.openingBalance +
        _totalSalesRemaining -
        _totalReturnCredits -
        _totalReceipts;
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E9EB)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 21),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'كشف حساب عميل',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                          constraints: const BoxConstraints(maxWidth: 1050),
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
        decoration: const InputDecoration(
          labelText: 'العميل',
          border: OutlineInputBorder(),
        ),
        hint: const Text('اختار العميل'),
        items: _customers
            .map(
              (customer) => DropdownMenuItem<Customer>(
                value: customer,
                child: Text(customer.name),
              ),
            )
            .toList(),
        onChanged: _onCustomerChanged,
      ),
    );
  }

  Widget _buildSummary(Customer customer, double balance) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'رصيد قبل كده',
            value: _money(customer.openingBalance),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'إجمالي المبيعات',
            value: _money(_totalSales),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'إجمالي المرتجعات',
            value: _money(_totalReturns),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'إجمالي اللي اتدفع',
            value: _money(_totalReceipts),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'عليه دلوقتي',
            value: _money(balance),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    final rows = <_StatementRow>[];

    for (final sale in _sales) {
      rows.add(
        _StatementRow(
          date: sale.date,
          title: 'فاتورة بيع',
          subtitle: 'إجمالي ${_money(sale.total)}',
          amount: sale.remainingAmount,
          isReceipt: false,
        ),
      );
    }

    for (final saleReturn in _returns) {
      final credit = (saleReturn.total - saleReturn.refundedAmount)
          .clamp(0.0, double.infinity)
          .toDouble();
      rows.add(
        _StatementRow(
          date: saleReturn.date,
          title: 'مرتجع بيع',
          subtitle: 'قيمة المرتجع ${_money(saleReturn.total)}',
          amount: credit,
          isReceipt: true,
        ),
      );
    }

    for (final payment in _payments) {
      rows.add(
        _StatementRow(
          date: payment.date,
          title: 'تحصيل دفعة',
          subtitle: payment.notes ?? 'تحصيل من العميل',
          amount: payment.amount,
          isReceipt: true,
        ),
      );
    }

    rows.sort((a, b) => b.date.compareTo(a.date));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الحركات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لسه مفيش حركات على الحساب')),
            )
          else
            ...rows.map(
              (row) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  row.isReceipt ? Icons.arrow_downward : Icons.receipt_long,
                  color: row.isReceipt
                      ? Colors.green
                      : const Color(0xFF0E4C4C),
                ),
                title: Text(row.title),
                subtitle: Text('${_date(row.date)} — ${row.subtitle}'),
                trailing: Text(
                  '${row.isReceipt ? '+' : '-'}${_money(row.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            _customers.isEmpty
                ? 'لسه مفيش عملاء'
                : 'اختار العميل عشان تشوف حسابه',
          ),
        ),
      ),
    );
  }
}

class _StatementRow {
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final bool isReceipt;

  const _StatementRow({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isReceipt,
  });
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
