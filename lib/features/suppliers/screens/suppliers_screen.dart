import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/supplier.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/screens/purchase_invoice_screen.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:dafter/features/suppliers/screens/add_supplier_screen.dart';
import 'package:dafter/features/suppliers/screens/supplier_payment_screen.dart';
import 'package:dafter/features/suppliers/screens/supplier_statement_screen.dart';
import 'package:dafter/features/suppliers/widgets/suppliers_filter_bar.dart';
import 'package:dafter/features/suppliers/widgets/suppliers_summary_row.dart';
import 'package:dafter/features/suppliers/widgets/suppliers_table.dart';
import 'package:flutter/material.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SupplierRepository _supplierRepository = SupplierRepository();
  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'الكل';
  String searchQuery = '';
  List<Supplier> suppliers = [];
  List<Purchase> purchases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _supplierRepository.getSuppliers(),
        _purchaseRepository.getPurchases(),
      ]);

      if (!mounted) return;

      setState(() {
        suppliers = results[0] as List<Supplier>;
        purchases = results[1] as List<Purchase>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('حصلت مشكلة وإحنا بنجيب بيانات الموردين');
    }
  }

  List<Supplier> get filteredSuppliers {
    Iterable<Supplier> result = suppliers;

    if (selectedFilter == 'عليهم مستحقات') {
      result = result.where((supplier) => supplier.balance > 0);
    } else if (selectedFilter == 'بدون مستحقات') {
      result = result.where((supplier) => supplier.balance <= 0);
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((supplier) {
        final name = supplier.name.toLowerCase();
        final phone = supplier.phone?.toLowerCase() ?? '';
        return name.contains(query) || phone.contains(query);
      });
    }

    return result.toList();
  }

  double get totalDue => suppliers.fold<double>(
    0,
    (sum, supplier) => sum + (supplier.balance > 0 ? supplier.balance : 0),
  );

  double get monthlyPurchases {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    return purchases.fold<double>(
      0,
      (sum, purchase) =>
          purchase.date.isBefore(nextMonth) &&
              !purchase.date.isBefore(monthStart)
          ? sum + purchase.total
          : sum,
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(Widget screen) async {
    await Nav.push(context, screen);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    onTap: () => _open(const SupplierStatementScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.person_add_outlined,
                    label: 'إضافة مورد',
                    primary: false,
                    onTap: () => _open(const AddSupplierScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.payments_outlined,
                    label: 'سداد دفعة',
                    primary: false,
                    onTap: () => _open(const SupplierPaymentScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.shopping_bag_outlined,
                    label: 'فاتورة شراء',
                    primary: true,
                    onTap: () => _open(const PurchaseInvoiceScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SuppliersSummaryRow(
              totalSuppliers: suppliers.length,
              totalDue: totalDue,
              monthlyPurchases: monthlyPurchases,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E9EB)),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        SuppliersFilterBar(
                          selectedFilter: selectedFilter,
                          count: filteredSuppliers.length,
                          searchController: _searchController,
                          onSearchChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                          onFilterSelected: (value) {
                            setState(() => selectedFilter = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        SuppliersTable(
                          suppliers: filteredSuppliers,
                          onSupplierTap: (supplier) => _open(
                            SupplierStatementScreen(supplierId: supplier.id),
                          ),
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
