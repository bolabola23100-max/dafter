import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/model/purchase.dart';
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

  // =========================================================
  // Real Purchases Data
  // =========================================================

  List<Purchase> invoices = [];

  bool _isLoading = true;

  // =========================================================
  // Init
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  // =========================================================
  // Dispose
  // =========================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // Load Purchases
  // =========================================================

  Future<void> _loadPurchases() async {
    /*
     * هنربط هنا PurchaseService بعد ما نعمله.
     *
     * حاليًا مفيش أي بيانات وهمية.
     */

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      invoices = [];
    });
  }

  // =========================================================
  // Filtered Invoices
  // =========================================================

  List<Purchase> get filteredInvoices {
    var result = List<Purchase>.from(invoices);

    // -------------------------------------------------------
    // Payment Filter
    // -------------------------------------------------------

    if (selectedFilter == 'نقدي') {
      result = result.where((invoice) {
        return invoice.remainingAmount <= 0;
      }).toList();
    }

    if (selectedFilter == 'آجل') {
      result = result.where((invoice) {
        return invoice.remainingAmount > 0;
      }).toList();
    }

    if (selectedFilter == 'غير مكتمل') {
      result = result.where((invoice) {
        return invoice.remainingAmount > 0;
      }).toList();
    }

    // -------------------------------------------------------
    // Search
    // -------------------------------------------------------

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

  // =========================================================
  // Summary
  // =========================================================

  double get totalPurchases {
    return invoices.fold(0, (sum, invoice) => sum + invoice.total);
  }

  double get totalPaid {
    return invoices.fold(0, (sum, invoice) => sum + invoice.paidAmount);
  }

  double get totalRemaining {
    return invoices.fold(0, (sum, invoice) => sum + invoice.remainingAmount);
  }

  // =========================================================
  // Message
  // =========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // =========================================================
  // Add Purchase
  // =========================================================

  Future<void> _openPurchaseInvoice() async {
    await Nav.push(context, const PurchaseInvoiceScreen());

    if (!mounted) return;

    await _loadPurchases();
  }

  // =========================================================
  // Add Supplier
  // =========================================================

  Future<void> _openAddSupplier() async {
    await Nav.push(context, const AddSupplierScreen());

    if (!mounted) return;

    await _loadPurchases();
  }

  // =========================================================
  // Purchase Report
  // =========================================================

  Future<void> _openPurchaseReport() async {
    await Nav.push(context, const PurchaseReportScreen());
  }

  // =========================================================
  // Purchase Return
  // =========================================================

  Future<void> _openPurchaseReturn() async {
    await Nav.push(context, const PurchaseReturnScreen());

    if (!mounted) return;

    await _loadPurchases();
  }

  // =========================================================
  // Invoice Menu
  // =========================================================

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

  // =========================================================
  // Delete Invoice
  // =========================================================

  Future<void> _deleteInvoice(Purchase invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('حذف الفاتورة؟'),
          content: Text(
            'هل أنت متأكد من حذف فاتورة '
            '#${invoice.id}؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Nav.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Nav.pop(context, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    /*
     * هنربط هنا PurchaseService.deletePurchase()
     * بعد ما نعمل الـ Repository والـ Service.
     */

    if (!mounted) return;

    _showMessage('سيتم ربط حذف الفاتورة بقاعدة البيانات');
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =====================================================
          // Action Buttons
          // =====================================================
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

          // =====================================================
          // Summary Cards
          // =====================================================
          PurchasesSummaryRow(
            totalPurchases: totalPurchases,
            invoicesCount: invoices.length,
            totalPaid: totalPaid,
            totalRemaining: totalRemaining,
          ),

          const SizedBox(height: 20),

          // =====================================================
          // Invoices Section
          // =====================================================
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
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  onSearchChanged: (_) {
                    setState(() {});
                  },
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
