import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dafter/features/reports/model/report_summary.dart';

class ReportExportService {
  Future<bool> exportPdf({
    required ReportSummary summary,
    required String period,
    String report = 'كل التقارير',
  }) async {
    final location = await getSaveLocation(
      suggestedName: 'تقرير_دفتر.pdf',
      acceptedTypeGroups: const [XTypeGroup(label: 'PDF', extensions: ['pdf'])],
    );
    if (location == null) return false;

    final bytes = await _buildPdf(summary, period, report);
    await XFile.fromData(bytes, name: 'تقرير_دفتر.pdf', mimeType: 'application/pdf').saveTo(location.path);
    return true;
  }

  Future<bool> exportExcel({
    required ReportSummary summary,
    required String period,
    String report = 'كل التقارير',
  }) async {
    final location = await getSaveLocation(
      suggestedName: 'تقرير_دفتر.xlsx',
      acceptedTypeGroups: const [XTypeGroup(label: 'Excel', extensions: ['xlsx'])],
    );
    if (location == null) return false;

    final excel = Excel.createExcel();
    final sheet = excel['التقرير'];
    sheet.appendRow([TextCellValue('تقرير دفتر')]);
    sheet.appendRow([TextCellValue('الفترة'), TextCellValue(period)]);
    sheet.appendRow([TextCellValue('نوع التقرير'), TextCellValue(report)]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('البند'), TextCellValue('العدد'), TextCellValue('القيمة')]);
    _appendExcelRow(sheet, 'المبيعات', summary.salesCount, summary.salesTotal);
    _appendExcelRow(sheet, 'مرتجعات البيع', summary.salesReturnsCount, summary.salesReturnsTotal);
    _appendExcelRow(sheet, 'صافي المبيعات', null, summary.netSales);
    _appendExcelRow(sheet, 'المشتريات', summary.purchasesCount, summary.purchasesTotal);
    _appendExcelRow(sheet, 'مرتجعات الشراء', summary.purchaseReturnsCount, summary.purchaseReturnsTotal);
    _appendExcelRow(sheet, 'صافي المشتريات', null, summary.netPurchases);
    _appendExcelRow(sheet, 'المصروفات', summary.expensesCount, summary.expensesTotal);
    _appendExcelRow(sheet, 'الصافي', null, summary.net);
    _appendExcelRow(sheet, 'قيمة المخزون', null, summary.stockValue);
    _appendExcelRow(sheet, 'المنتجات', summary.productsCount, null);
    _appendExcelRow(sheet, 'الموردين', summary.suppliersCount, null);
    _appendExcelRow(sheet, 'العملاء', summary.customersCount, null);

    final data = excel.encode();
    if (data == null) return false;
    await File(location.path).writeAsBytes(data, flush: true);
    return true;
  }

  void _appendExcelRow(Sheet sheet, String title, int? count, double? value) {
    sheet.appendRow([
      TextCellValue(title),
      count == null ? TextCellValue('') : IntCellValue(count),
      value == null ? TextCellValue('') : DoubleCellValue(value),
    ]);
  }

  Future<Uint8List> _buildPdf(ReportSummary summary, String period, String report) async {
    final document = pw.Document();
    pw.Font? regular;
    pw.Font? bold;

    const fontPaths = ['C:\\Windows\\Fonts\\arial.ttf', 'C:\\Windows\\Fonts\\tahoma.ttf'];
    const boldPaths = ['C:\\Windows\\Fonts\\arialbd.ttf', 'C:\\Windows\\Fonts\\tahomabd.ttf'];

    for (final path in fontPaths) {
      final file = File(path);
      if (await file.exists()) {
        regular = pw.Font.ttf(await file.readAsBytes());
        break;
      }
    }
    for (final path in boldPaths) {
      final file = File(path);
      if (await file.exists()) {
        bold = pw.Font.ttf(await file.readAsBytes());
        break;
      }
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (_) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('تقرير دفتر', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('الفترة: $period'),
                pw.Text('نوع التقرير: $report'),
                pw.SizedBox(height: 20),
                _pdfTable(summary),
              ],
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _pdfTable(ReportSummary s) {
    final rows = <List<String>>[
      ['البند', 'العدد', 'القيمة'],
      ['المبيعات', '${s.salesCount}', _money(s.salesTotal)],
      ['مرتجعات البيع', '${s.salesReturnsCount}', _money(s.salesReturnsTotal)],
      ['صافي المبيعات', '', _money(s.netSales)],
      ['المشتريات', '${s.purchasesCount}', _money(s.purchasesTotal)],
      ['مرتجعات الشراء', '${s.purchaseReturnsCount}', _money(s.purchaseReturnsTotal)],
      ['صافي المشتريات', '', _money(s.netPurchases)],
      ['المصروفات', '${s.expensesCount}', _money(s.expensesTotal)],
      ['الصافي', '', _money(s.net)],
      ['قيمة المخزون', '', _money(s.stockValue)],
      ['المنتجات', '${s.productsCount}', ''],
      ['الموردين', '${s.suppliersCount}', ''],
      ['العملاء', '${s.customersCount}', ''],
    ];

    return pw.TableHelper.fromTextArray(
      headers: rows.first,
      data: rows.skip(1).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerRight,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey400),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }

  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';
}
