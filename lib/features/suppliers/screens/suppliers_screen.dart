import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/model/supplier.dart';
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

  String selectedFilter = 'الكل';

  List<Supplier> suppliers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  // =========================
  // Load Suppliers
  // =========================

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _supplierRepository.getSuppliers();

      if (!mounted) return;

      setState(() {
        suppliers = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحميل الموردين: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================
  // Filter
  // =========================

  List<Supplier> get filteredSuppliers {
    if (selectedFilter == 'عليهم مستحقات') {
      return suppliers.where((supplier) => supplier.balance > 0).toList();
    }

    if (selectedFilter == 'بدون مستحقات') {
      return suppliers.where((supplier) => supplier.balance <= 0).toList();
    }

    return suppliers;
  }

  // =========================
  // Coming Soon
  // =========================

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title - الشاشة قيد التجهيز'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // Build
  // =========================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  onTap: () {
                    Nav.push(context, const SupplierStatementScreen());
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'إضافة مورد',
                  primary: false,
                  onTap: () async {
                    await Nav.push(context, const AddSupplierScreen());

                    await _loadSuppliers();
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'سداد دفعة',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const SupplierPaymentScreen());
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ActionButton(
                  icon: Icons.shopping_bag_outlined,
                  label: 'فاتورة شراء',
                  primary: true,
                  onTap: () async {
                    await Nav.push(context, const PurchaseInvoiceScreen());

                    await _loadSuppliers();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Summary
          // =========================================================
          SuppliersSummaryRow(totalSuppliers: suppliers.length),

          const SizedBox(height: 20),

          // =========================================================
          // Suppliers List
          // =========================================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E9EB)),
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      SuppliersFilterBar(
                        selectedFilter: selectedFilter,
                        count: filteredSuppliers.length,
                        onFilterSelected: (filter) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      SuppliersTable(
                        suppliers: filteredSuppliers,
                        onSupplierTap: (supplier) {
                          _showComingSoon('كشف حساب ${supplier.name}');
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
