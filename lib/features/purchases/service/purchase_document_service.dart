import 'dart:typed_data';

import 'package:dafter/features/model/purchase.dart';
import 'package:dafter/features/model/product.dart';
import 'package:dafter/features/purchases/repo/purchase_repository.dart';
import 'package:dafter/features/Products/repo/product_repository.dart';
import 'package:dafter/features/suppliers/repo/supplier_repository.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PurchaseDocumentService {
  final PurchaseRepository _purchaseRepository;
  final ProductRepository _productRepository;
  final SupplierRepository _supplierRepository;

  PurchaseDocumentService({
    PurchaseRepository? purchaseRepository,
    ProductRepository? productRepository,
    SupplierRepository? supplierRepository,
  }) : _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
       _productRepository = productRepository ?? ProductRepository(),
       _supplierRepository = supplierRepository ?? SupplierRepository();

  Future<Uint8List> buildPdf(Purchase purchase) async {
    final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
    final font = pw.Font.ttf(fontData);
    final supplier = purchase.supplierId == null
        ? null
        : await _supplierRepository.getSupplierById(purchase.supplierId!);
    final products = <String, Product>{};
    for (final item in purchase.items) {
      final product = await _productRepository.getProductById(item.productId);
      if (product != null) products[item.productId] = product;
    }

    final document = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      build: (_) => [
        pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Text('فاتورة شراء', style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 10),
          pw.Text('رقم الفاتورة: ${purchase.id}', style: pw.TextStyle(font: font)),
          pw.Text('التاريخ: ${_date(purchase.date)}', style: pw.TextStyle(font: font)),
          pw.Text('المورد: ${supplier?.name ?? 'بدون مورد'}', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 18),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400), children: [
            _row(font, 'الإجمالي', 'الكمية', 'سعر الوحدة', 'الصنف', header: true),
            ...purchase.items.map((item) => _row(font, '${item.subtotal.toStringAsFixed(2)} ج.م', '${item.quantity}', '${item.price.toStringAsFixed(2)} ج.م', products[item.productId]?.name ?? item.productId)),
          ]),
          pw.SizedBox(height: 18),
          pw.Text('الإجمالي: ${purchase.total.toStringAsFixed(2)} ج.م', style: pw.TextStyle(font: font, fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.Text('المدفوع: ${purchase.paidAmount.toStringAsFixed(2)} ج.م', style: pw.TextStyle(font: font)),
          pw.Text('المتبقي: ${purchase.remainingAmount.toStringAsFixed(2)} ج.م', style: pw.TextStyle(font: font)),
          if (purchase.notes != null && purchase.notes!.trim().isNotEmpty) pw.Text('ملاحظات: ${purchase.notes}', style: pw.TextStyle(font: font)),
        ])),
      ],
    ));
    return document.save();
  }

  pw.TableRow _row(pw.Font font, String total, String quantity, String price, String name, {bool header = false}) {
    final style = pw.TextStyle(font: font, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(total, style: style, textAlign: pw.TextAlign.center)),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(quantity, style: style, textAlign: pw.TextAlign.center)),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(price, style: style, textAlign: pw.TextAlign.center)),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(name, style: style, textAlign: pw.TextAlign.right)),
    ]);
  }

  Future<bool> savePdf(Purchase purchase) async {
    final location = await getSaveLocation(suggestedName: 'فاتورة_شراء_${purchase.id}.pdf', acceptedTypeGroups: const [XTypeGroup(label: 'PDF', extensions: ['pdf'])]);
    if (location == null) return false;
    final bytes = await buildPdf(purchase);
    await XFile.fromData(bytes, name: 'فاتورة_شراء_${purchase.id}.pdf', mimeType: 'application/pdf').saveTo(location.path);
    return true;
  }

  Future<void> printPdf(Purchase purchase) async {
    final bytes = await buildPdf(purchase);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
