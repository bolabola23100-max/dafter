import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/customers/model/customer.dart';
import 'package:dafter/features/customers/screens/add_customer_screen.dart';
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
  bool showDebtorsOnly = false;

  // بيانات وهمية - هتتربط بقاعدة البيانات بعدين
  final List<Customer> _customers = [
    Customer(
      name: 'مؤسسة الأفق للتجارة',
      phone: '0501234567',
      totalPurchases: 12500,
      paid: 10000,
    ),
    Customer(
      name: 'شركة الرمال الذهبية',
      phone: '0559876543',
      totalPurchases: 8200,
      paid: 8200,
    ),
    Customer(
      name: 'محلات السعادة للهواتف',
      phone: '0561122334',
      totalPurchases: 45000,
      paid: 30000,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    return _customers.where((c) {
      final matchesSearch =
          _searchController.text.isEmpty ||
          c.name.contains(_searchController.text) ||
          c.phone.contains(_searchController.text);
      final matchesDebt = !showDebtorsOnly || c.remaining > 0;
      return matchesSearch && matchesDebt;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // Action Buttons
          // =========================================================
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'كشف حساب',
                  primary: false,
                  onTap: () => _showSelectCustomerDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'إضافة عميل',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const AddCustomerScreen());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'تحصيل دفعة',
                  primary: false,
                  onTap: () {
                    Nav.push(
                      context,
                      RecordPaymentScreen(customers: _customers),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.shopping_cart_outlined,
                  label: 'فاتورة بيع',
                  primary: true,
                  onTap: () {
                    Nav.push(context, const SalesInvoiceScreen());
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Summary Cards
          // =========================================================
          CustomersSummaryRow(totalCustomers: _customers.length),

          const SizedBox(height: 20),

          // =========================================================
          // Search & Filters
          // =========================================================
          CustomersFilterBar(
            searchController: _searchController,
            showDebtorsOnly: showDebtorsOnly,
            onDebtorsFilterChanged: (value) =>
                setState(() => showDebtorsOnly = value),
            onSearchChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          // =========================================================
          // Customers Table
          // =========================================================
          Expanded(
            child: CustomersTable(
              customers: _filteredCustomers,
              onViewCustomer: (c) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تفاصيل العميل: ${c.name}')),
                );
              },
              onRecordPayment: (c) {
                Nav.push(
                  context,
                  RecordPaymentScreen(customers: [c]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectCustomerDialog() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          title: const Text('اختر العميل'),
          content: SizedBox(
            width: 350,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final c = _customers[index];
                return ListTile(
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  onTap: () {
                    Nav.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('كشف حساب ${c.name} — قريبًا')),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
