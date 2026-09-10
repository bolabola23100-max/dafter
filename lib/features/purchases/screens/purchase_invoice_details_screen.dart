import 'package:flutter/material.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/purchases/service/purchase_document_service.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';

class PurchaseInvoiceDetailsScreen extends StatefulWidget {
  final Purchase purchase;

  const PurchaseInvoiceDetailsScreen({
    super.key,
    required this.purchase,
  });

  @override
  State<PurchaseInvoiceDetailsScreen> createState() =>
      _PurchaseInvoiceDetailsScreenState();
}

class _PurchaseInvoiceDetailsScreenState
    extends State<PurchaseInvoiceDetailsScreen> {
  final _products = ProductRepository();
  final _suppliers = SupplierRepository();
  final _documents = PurchaseDocumentService();
  final Map<String, String> _names = {};
  String? _supplierName;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.purchase.supplierId != null) {
        final supplier = await _suppliers.getSupplierById(
          widget.purchase.supplierId!,
        );
        _supplierName = supplier?.name;
      }

      for (final item in widget.purchase.items) {
        final product = await _products.getProductById(item.productId);
        if (product != null) {
          _names[item.productId] = product.name;
        }
      }
    } catch (e) {
      if (mounted) _message('تعذر تحميل بيانات الفاتورة: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await _documents.savePdf(widget.purchase);
      if (mounted && saved) {
        _message('تم حفظ الفاتورة PDF بنجاح');
      }
    } catch (e) {
      if (mounted) _message('تعذر حفظ PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _documents.printPdf(widget.purchase);
    } catch (e) {
      if (mounted) _message('تعذر الطباعة: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchase = widget.purchase;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8F9),
        appBar: AppBar(
          title: Text('فاتورة شراء #${purchase.id}'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _busy ? null : _pdf,
              tooltip: 'حفظ PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              onPressed: _busy ? null : _print,
              tooltip: 'طباعة',
              icon: const Icon(Icons.print_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'المورد: ${_supplierName ?? 'بدون مورد'}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('التاريخ: ${_date(purchase.date)}'),
                          const SizedBox(height: 6),
                          Text('رقم الفاتورة: ${purchase.id}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'الأصناف',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...purchase.items.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _names[item.productId] ?? item.productId,
                              ),
                              subtitle: Text(
                                '${item.quantity} × ${item.price.toStringAsFixed(2)} ج.م',
                              ),
                              trailing: Text(
                                '${item.subtotal.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'الإجمالي: ${purchase.total.toStringAsFixed(2)} ج.م',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'المدفوع: ${purchase.paidAmount.toStringAsFixed(2)} ج.م',
                          ),
                          Text(
                            'المتبقي: ${purchase.remainingAmount.toStringAsFixed(2)} ج.م',
                          ),
                          if (purchase.notes != null &&
                              purchase.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('ملاحظات: ${purchase.notes}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9EB)),
      ),
      child: child,
    );
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
