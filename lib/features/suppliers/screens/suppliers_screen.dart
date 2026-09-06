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
  final SupplierRepository _repository = SupplierRepository();
  String selectedFilter = 'الكل';
  List<Supplier> suppliers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _repository.getSuppliers();
      if (!mounted) return;
      setState(() { suppliers = result; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('حصلت مشكلة وإحنا بنجيب الموردين');
    }
  }

  List<Supplier> get filteredSuppliers {
    if (selectedFilter == 'عليهم مستحقات') return suppliers.where((s) => s.balance > 0).toList();
    if (selectedFilter == 'بدون مستحقات') return suppliers.where((s) => s.balance <= 0).toList();
    return suppliers;
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(Widget screen) async {
    await Nav.push(context, screen);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: ActionButton(icon: Icons.receipt_long_outlined, label: 'كشف حساب', primary: false, onTap: () => _open(const SupplierStatementScreen()))),
          const SizedBox(width: 12),
          Expanded(child: ActionButton(icon: Icons.person_add_outlined, label: 'إضافة مورد', primary: false, onTap: () => _open(const AddSupplierScreen()))),
          const SizedBox(width: 12),
          Expanded(child: ActionButton(icon: Icons.payments_outlined, label: 'سداد دفعة', primary: false, onTap: () => _open(const SupplierPaymentScreen()))),
          const SizedBox(width: 12),
          Expanded(child: ActionButton(icon: Icons.shopping_bag_outlined, label: 'فاتورة شراء', primary: true, onTap: () => _open(const PurchaseInvoiceScreen()))),
        ]),
        const SizedBox(height: 20),
        SuppliersSummaryRow(totalSuppliers: suppliers.length),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
          child: _loading
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              : Column(children: [
                  SuppliersFilterBar(selectedFilter: selectedFilter, count: filteredSuppliers.length, onFilterSelected: (value) => setState(() => selectedFilter = value)),
                  const SizedBox(height: 14),
                  SuppliersTable(
                    suppliers: filteredSuppliers,
                    onSupplierTap: (supplier) => _open(SupplierStatementScreen(supplierId: supplier.id)),
                  ),
                ]),
        ),
      ]),
    );
  }
}
