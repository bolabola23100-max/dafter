import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/model/customer.dart';
import 'package:dafter/features/customers/repo/customer_repository.dart';
import 'package:dafter/features/customers/screens/add_customer_screen.dart';
import 'package:dafter/features/customers/screens/customer_statement_screen.dart';
import 'package:dafter/features/customers/screens/record_payment_screen.dart';
import 'package:dafter/features/customers/widgets/customers_filter_bar.dart';
import 'package:dafter/features/customers/widgets/customers_summary_row.dart';
import 'package:dafter/features/customers/widgets/customers_table.dart';
import 'package:dafter/features/sales/screens/sales_invoice_screen.dart';
import 'package:flutter/material.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  final _repository = CustomerRepository();
  List<Customer> _customers = [];
  bool showDebtorsOnly = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _repository.getCustomers();
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('مش قادر أجيب العملاء: $e')),
      );
    }
  }

  List<Customer> get _filteredCustomers {
    final query = _searchController.text.trim().toLowerCase();
    return _customers.where((customer) {
      final matchesSearch =
          query.isEmpty ||
          customer.name.toLowerCase().contains(query) ||
          (customer.phone ?? '').contains(query);
      final matchesDebt = !showDebtorsOnly || customer.balance > 0;
      return matchesSearch && matchesDebt;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt = _customers.fold<double>(
      0,
      (sum, customer) => sum + (customer.balance > 0 ? customer.balance : 0),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'كشف حساب',
                  primary: false,
                  onTap: _showSelectCustomerDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'إضافة عميل',
                  primary: false,
                  onTap: () async {
                    final saved = await Nav.push(
                      context,
                      const AddCustomerScreen(),
                    );
                    if (saved == true) _loadCustomers();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'تحصيل دفعة',
                  primary: false,
                  onTap: _showPaymentForAnyCustomer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.shopping_cart_outlined,
                  label: 'فاتورة بيع',
                  primary: true,
                  onTap: () => Nav.push(context, const SalesInvoiceScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomersSummaryRow(
            totalCustomers: _customers.length,
            totalDebt: totalDebt,
          ),
          const SizedBox(height: 20),
          CustomersFilterBar(
            searchController: _searchController,
            showDebtorsOnly: showDebtorsOnly,
            onDebtorsFilterChanged: (value) =>
                setState(() => showDebtorsOnly = value),
            onSearchChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomersTable(
                    customers: _filteredCustomers,
                    onViewCustomer: _showCustomerDetails,
                    onRecordPayment: _recordPayment,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSelectCustomerDialog() async {
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لسه مفيش عملاء')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          title: const Text('اختار العميل'),
          content: SizedBox(
            width: 350,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(
                    '${customer.balance.toStringAsFixed(2)} جنيه عليه',
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Nav.push(
                      context,
                      CustomerStatementScreen(customerId: customer.id),
                    );
                    if (mounted) _loadCustomers();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentForAnyCustomer() {
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ضيف عميل الأول')),
      );
      return;
    }
    Nav.push(
      context,
      RecordPaymentScreen(customers: _customers),
    ).then((_) => _loadCustomers());
  }

  void _recordPayment(Customer customer) {
    Nav.push(
      context,
      RecordPaymentScreen(customers: [customer]),
    ).then((_) => _loadCustomers());
  }

  void _showCustomerDetails(Customer customer) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer.name),
        content: Text(
          'الرصيد الحالي: ${customer.balance.toStringAsFixed(2)} جنيه\n\n'
          '${customer.balance > 0 ? 'العميل عليه فلوس.' : 'مفيش عليه فلوس حالياً.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تمام'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Nav.push(
                context,
                CustomerStatementScreen(customerId: customer.id),
              );
            },
            child: const Text('كشف الحساب'),
          ),
        ],
      ),
    );
  }
}
