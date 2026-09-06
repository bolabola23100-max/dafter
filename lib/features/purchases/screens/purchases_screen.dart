import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/screens/purchase_invoice_screen.dart';
import 'package:dafter/features/purchases/screens/purchase_report_screen.dart';
import 'package:dafter/features/purchases/screens/purchase_return_screen.dart';
import 'package:dafter/features/purchases/widgets/purchase_invoice_menu_sheet.dart';
import 'package:dafter/features/purchases/widgets/purchases_filter_bar.dart';
import 'package:dafter/features/purchases/widgets/purchases_summary_row.dart';
import 'package:dafter/features/purchases/widgets/purchases_table.dart';
import 'package:dafter/features/suppliers/screens/add_supplier_screen.dart';
import 'package:flutter/material.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  String selectedFilter = 'الكل';
  final TextEditingController searchController = TextEditingController();
  final PurchaseRepository _purchaseRepository = PurchaseRepository();

  List<Purchase> invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchases() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final purchases = await _purchaseRepository.getPurchases();

      if (!mounted) return;

      setState(() {
        invoices = purchases;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('تعذر تحميل فواتير الشراء: $e');
    }
  }

  List<Purchase> get filteredInvoices {
    var result = List<Purchase>.from(invoices);

    if (selectedFilter == 'نقدي') {
      result = result.where((invoice) => invoice.remainingAmount <= 0).toList();
    }

    if (selectedFilter == 'آجل') {
      result = result.where((invoice) => invoice.remainingAmount > 0).toList();
    }

    if (selectedFilter == 'غير مكتمل') {
      result = result.where((invoice) => invoice.remainingAmount > 0).toList();
    }

    final query = searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((invoice) {
        final invoiceId = invoice.id.toLowerCase();
        final supplierId = invoice.supplierId?.toLowerCase() ?? '';
        return invoiceId.contains(query) || supplierId.contains(query);
      }).toList();
    }

    return result;
  }

  double get totalPurchases =>
      invoices.fold(0, (sum, invoice) => sum + invoice.total);

  double get totalPaid =>
      invoices.fold(0, (sum, invoice) => sum + invoice.paidAmount);

  double get totalRemaining =>
      invoices.fold(0, (sum, invoice) => sum + invoice.remainingAmount);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openPurchaseInvoice() async {
    final result = await Nav.push(context, const PurchaseInvoiceScreen());

    if (!mounted) return;

    if (result == true) {
      await _loadPurchases();
    }
  }

  Future<void> _openAddSupplier() async {
    final result = await Nav.push(context, const AddSupplierScreen());

    if (!mounted) return;

    if (result == true) {
      await _loadPurchases();
    }
  }

  Future<void> _openPurchaseReport() async {
    await Nav.push(context, const PurchaseReportScreen());
  }

  Future<void> _openPurchaseReturn() async {
    final result = await Nav.push(context, const PurchaseReturnScreen());

    if (!mounted) return;

    if (result == true) {
      await _loadPurchases();
    }
  }

  void _showInvoiceMenu(Purchase invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return PurchaseInvoiceMenuSheet(
          invoice: invoice,
          onView: () {
            Nav.pop(context);
            _showMessage('عرض فاتورة #${invoice.id}');
          },
          onPdf: () {
            Nav.pop(context);
            _showMessage('سيتم تجهيز PDF لاحقًا');
          },
          onPrint: () {
            Nav.pop(context);
            _showMessage('سيتم تجهيز الطباعة لاحقًا');
          },
          onReturn: () {
            Nav.pop(context);
            _showMessage('إنشاء مرتجع شراء');
          },
          onDelete: () {
            Nav.pop(context);
            _deleteInvoice(invoice);
          },
        );
      },
    );
  }

  Future<void> _deleteInvoice(Purchase invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('حذف الفاتورة؟'),
          content: Text('هل أنت متأكد من حذف فاتورة #${invoice.id}؟'),
          actions: [
            TextButton(
              onPressed: () => Nav.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Nav.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _showMessage('سيتم ربط حذف الفاتورة بقاعدة البيانات');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'كشف المشتريات',
                  primary: false,
                  onTap: _openPurchaseReport,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.person_add_outlined,
                  label: 'إضافة مورد',
                  primary: false,
                  onTap: _openAddSupplier,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.assignment_return_outlined,
                  label: 'مرتجع شراء',
                  primary: false,
                  onTap: _openPurchaseReturn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.add_shopping_cart_outlined,
                  label: 'فاتورة شراء',
                  primary: true,
                  onTap: _openPurchaseInvoice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PurchasesSummaryRow(
            totalPurchases: totalPurchases,
            invoicesCount: invoices.length,
            totalPaid: totalPaid,
            totalRemaining: totalRemaining,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E9EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PurchasesFilterBar(
                  selectedFilter: selectedFilter,
                  searchController: searchController,
                  count: filteredInvoices.length,
                  onFilterSelected: (filter) {
                    setState(() => selectedFilter = filter);
                  },
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : PurchasesTable(
                        invoices: filteredInvoices,
                        onInvoiceTap: _showInvoiceMenu,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
