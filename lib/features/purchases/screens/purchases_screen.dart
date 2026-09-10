import 'package:flutter/material.dart';
import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/purchases/screens/purchase_invoice_details_screen.dart';
import 'package:dafter/features/purchases/screens/purchase_invoice_screen.dart';
import 'package:dafter/features/purchases/screens/purchase_report_screen.dart';
import 'package:dafter/features/purchases/screens/purchase_return_screen.dart';
import 'package:dafter/features/purchases/service/purchase_document_service.dart';
import 'package:dafter/features/purchases/widgets/purchase_invoice_menu_sheet.dart';
import 'package:dafter/features/purchases/widgets/purchases_filter_bar.dart';
import 'package:dafter/features/purchases/widgets/purchases_summary_row.dart';
import 'package:dafter/features/purchases/widgets/purchases_table.dart';
import 'package:dafter/features/suppliers/screens/add_supplier_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _searchController = TextEditingController();
  final _repository = PurchaseRepository();
  final _documents = PurchaseDocumentService();
  List<Purchase> _invoices = [];
  String _filter = 'الكل';
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try { final data = await _repository.getPurchases(); if (mounted) setState(() { _invoices = data; _loading = false; }); }
    catch (e) { if (mounted) { setState(() => _loading = false); _message('تعذر تحميل فواتير الشراء: $e'); } }
  }

  List<Purchase> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _invoices.where((p) {
      final matchesFilter = _filter == 'الكل' || (_filter == 'مدفوع' && p.remainingAmount <= .009) || (_filter == 'آجل' && p.remainingAmount > .009);
      final matchesSearch = q.isEmpty || p.id.toLowerCase().contains(q) || (p.supplierId ?? '').toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  Future<void> _newPurchase() async { if (await Nav.push(context, const PurchaseInvoiceScreen()) == true) await _load(); }
  Future<void> _newSupplier() async { await Nav.push(context, const AddSupplierScreen()); if (mounted) await _load(); }
  Future<void> _report() async { await Nav.push(context, const PurchaseReportScreen()); }
  Future<void> _return() async { if (await Nav.push(context, const PurchaseReturnScreen()) == true) await _load(); }

  void _menu(Purchase invoice) {
    showModalBottomSheet<void>(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))), builder: (_) => PurchaseInvoiceMenuSheet(
      invoice: invoice,
      onView: () async { Navigator.pop(context); await Nav.push(context, PurchaseInvoiceDetailsScreen(purchase: invoice)); },
      onPdf: () async { Navigator.pop(context); try { final saved = await _documents.savePdf(invoice); if (mounted && saved) _message('تم حفظ PDF بنجاح'); } catch (e) { if (mounted) _message('تعذر حفظ PDF: $e'); } },
      onPrint: () async { Navigator.pop(context); try { await _documents.printPdf(invoice); } catch (e) { if (mounted) _message('تعذر الطباعة: $e'); } },
      onReturn: () async { Navigator.pop(context); await Nav.push(context, PurchaseReturnScreen(purchaseId: invoice.id)); if (mounted) await _load(); },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final invoices = _filtered;
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: ActionButton(icon: Icons.receipt_long_outlined, label: 'كشف المشتريات', primary: false, onTap: _report)), const SizedBox(width: 12), Expanded(child: ActionButton(icon: Icons.person_add_outlined, label: 'إضافة مورد', primary: false, onTap: _newSupplier)), const SizedBox(width: 12), Expanded(child: ActionButton(icon: Icons.assignment_return_outlined, label: 'مرتجع شراء', primary: false, onTap: _return)), const SizedBox(width: 12), Expanded(child: ActionButton(icon: Icons.add_shopping_cart_outlined, label: 'فاتورة شراء', primary: true, onTap: _newPurchase))]),
      const SizedBox(height: 20),
      PurchasesSummaryRow(totalPurchases: _invoices.fold(0, (s, p) => s + p.total), invoicesCount: _invoices.length, totalPaid: _invoices.fold(0, (s, p) => s + p.paidAmount), totalRemaining: _invoices.fold(0, (s, p) => s + p.remainingAmount)),
      const SizedBox(height: 20),
      Expanded(child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PurchasesFilterBar(selectedFilter: _filter, searchController: _searchController, count: invoices.length, onFilterSelected: (v) => setState(() => _filter = v), onSearchChanged: (_) => setState(() {})),
        const SizedBox(height: 14),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : PurchasesTable(invoices: invoices, onInvoiceTap: _menu)),
      ]))),
    ]));
  }
}
