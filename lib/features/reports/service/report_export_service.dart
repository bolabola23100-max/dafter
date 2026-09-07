import 'dart:typed_data';

import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/core/database/database_tables.dart';
import 'package:dafter/features/reports/model/report_summary.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExportService {
  ReportExportService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

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

    final bytes = await buildPdf(
      summary: summary,
      period: period,
      report: report,
    );
    await XFile.fromData(
      bytes,
      name: 'تقرير_دفتر.pdf',
      mimeType: 'application/pdf',
    ).saveTo(location.path);
    return true;
  }

  Future<Uint8List> buildPdf({
    required ReportSummary summary,
    required String period,
    String report = 'كل التقارير',
  }) async {
    final details = await _loadDetails(period);
    return _buildPdf(summary, period, report, details);
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

    final details = await _loadDetails(period);
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) excel.delete(defaultSheet);

    _addSummarySheet(excel, summary, period, report);
    if (_includes(report, 'المبيعات')) _addSheet(excel, 'المبيعات', details.sales, ['رقم الفاتورة', 'التاريخ', 'العميل', 'الإجمالي قبل الخصم', 'الخصم', 'الإجمالي', 'المدفوع', 'المتبقي', 'ملاحظات']);
    if (_includes(report, 'المشتريات')) _addSheet(excel, 'المشتريات', details.purchases, ['رقم الفاتورة', 'التاريخ', 'المورد', 'الإجمالي قبل الخصم', 'الخصم', 'الإجمالي', 'المدفوع', 'المتبقي', 'ملاحظات']);
    if (_includes(report, 'المصروفات')) _addSheet(excel, 'المصروفات', details.expenses, ['التاريخ', 'نوع المصروف', 'الحساب', 'المبلغ', 'ملاحظات']);
    if (_includes(report, 'مرتجعات البيع')) _addSheet(excel, 'مرتجعات البيع', details.saleReturns, ['رقم المرتجع', 'التاريخ', 'الفاتورة الأصلية', 'العميل', 'الإجمالي', 'المبلغ المرتجع', 'ملاحظات']);
    if (_includes(report, 'مرتجعات الشراء')) _addSheet(excel, 'مرتجعات الشراء', details.purchaseReturns, ['رقم المرتجع', 'التاريخ', 'الفاتورة الأصلية', 'المورد', 'الإجمالي', 'المبلغ المسترد', 'ملاحظات']);
    if (_includes(report, 'المخزون')) _addSheet(excel, 'المخزون', details.stock, ['المنتج', 'الباركود', 'الكمية', 'الحد الأدنى', 'سعر الشراء', 'سعر البيع', 'قيمة المخزون']);

    final data = excel.encode();
    if (data == null || data.isEmpty) return false;
    await XFile.fromData(
      Uint8List.fromList(data),
      name: 'تقرير_دفتر.xlsx',
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ).saveTo(location.path);
    return true;
  }

  bool _includes(String report, String section) {
    if (report == 'كل التقارير') return true;
    if (report == 'المبيعات') return section == 'المبيعات' || section == 'مرتجعات البيع';
    if (report == 'المشتريات') return section == 'المشتريات' || section == 'مرتجعات الشراء';
    if (report == 'المصروفات') return section == 'المصروفات';
    if (report == 'المخزون') return section == 'المخزون';
    if (report == 'صافي الحركة') return section == 'المبيعات' || section == 'المشتريات' || section == 'المصروفات' || section == 'مرتجعات البيع' || section == 'مرتجعات الشراء';
    return true;
  }

  void _addSummarySheet(Excel excel, ReportSummary s, String period, String report) {
    final sheet = excel['الملخص'];
    sheet.appendRow([TextCellValue('تقرير دفتر')]);
    sheet.appendRow([TextCellValue('الفترة'), TextCellValue(period)]);
    sheet.appendRow([TextCellValue('نوع التقرير'), TextCellValue(report)]);
    sheet.appendRow([TextCellValue('')]);
    final rows = <List<Object>>[
      ['البند', 'العدد', 'القيمة'],
      ['المبيعات', s.salesCount, s.salesTotal],
      ['مرتجعات البيع', s.salesReturnsCount, s.salesReturnsTotal],
      ['صافي المبيعات', '', s.netSales],
      ['المشتريات', s.purchasesCount, s.purchasesTotal],
      ['مرتجعات الشراء', s.purchaseReturnsCount, s.purchaseReturnsTotal],
      ['صافي المشتريات', '', s.netPurchases],
      ['المصروفات', s.expensesCount, s.expensesTotal],
      ['صافي الحركة', '', s.net],
      ['قيمة المخزون', '', s.stockValue],
      ['المنتجات', s.productsCount, ''],
      ['الموردين', s.suppliersCount, ''],
      ['العملاء', s.customersCount, ''],
    ];
    for (final row in rows) {
      sheet.appendRow(row.map((value) {
        if (value is int) return IntCellValue(value);
        if (value is double) return DoubleCellValue(value);
        return TextCellValue(value.toString());
      }).toList());
    }
  }

  void _addSheet(Excel excel, String name, List<List<String>> rows, List<String> headers) {
    final sheet = excel[name];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final row in rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }
    for (final row in sheet.rows) {
      for (final cell in row) {
        cell?.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }
  }

  Future<_ReportDetails> _loadDetails(String period) async {
    final db = await _database.database;
    final range = _periodRange(period);
    final args = [range.$1.toIso8601String(), range.$2.toIso8601String()];

    final sales = await db.rawQuery('''
      SELECT s.id, s.date, COALESCE(c.name, 'عميل نقدي') customer_name,
             s.subtotal, s.discount, s.total, s.paid_amount,
             (s.total - s.paid_amount) remaining, COALESCE(s.notes, '') notes
      FROM ${DatabaseTables.sales} s
      LEFT JOIN ${DatabaseTables.customers} c ON c.id = s.customer_id
      WHERE s.date >= ? AND s.date < ? ORDER BY s.date DESC
    ''', args);
    final purchases = await db.rawQuery('''
      SELECT p.id, p.date, COALESCE(s.name, 'بدون مورد') supplier_name,
             p.subtotal, p.discount, p.total, p.paid_amount,
             (p.total - p.paid_amount) remaining, COALESCE(p.notes, '') notes
      FROM ${DatabaseTables.purchases} p
      LEFT JOIN ${DatabaseTables.suppliers} s ON s.id = p.supplier_id
      WHERE p.date >= ? AND p.date < ? ORDER BY p.date DESC
    ''', args);
    final expenses = await db.rawQuery('''
      SELECT e.date, e.category, COALESCE(a.name, 'حساب محذوف') account_name,
             e.amount, COALESCE(e.notes, '') notes
      FROM ${DatabaseTables.expenses} e
      LEFT JOIN ${DatabaseTables.accounts} a ON a.id = e.account_id
      WHERE e.date >= ? AND e.date < ? ORDER BY e.date DESC
    ''', args);
    final saleReturns = await db.rawQuery('''
      SELECT r.id, r.date, r.sale_id, COALESCE(c.name, 'عميل نقدي') customer_name,
             r.total, r.refunded_amount, COALESCE(r.notes, '') notes
      FROM ${DatabaseTables.saleReturns} r
      LEFT JOIN ${DatabaseTables.customers} c ON c.id = r.customer_id
      WHERE r.date >= ? AND r.date < ? ORDER BY r.date DESC
    ''', args);
    final purchaseReturns = await db.rawQuery('''
      SELECT r.id, r.date, r.purchase_id, COALESCE(s.name, 'بدون مورد') supplier_name,
             r.total, r.refunded_amount, COALESCE(r.notes, '') notes
      FROM ${DatabaseTables.purchaseReturns} r
      LEFT JOIN ${DatabaseTables.suppliers} s ON s.id = r.supplier_id
      WHERE r.date >= ? AND r.date < ? ORDER BY r.date DESC
    ''', args);
    final stock = await db.rawQuery('''
      SELECT name, COALESCE(barcode, '') barcode, quantity, min_quantity,
             purchase_price, selling_price, (quantity * purchase_price) stock_value
      FROM ${DatabaseTables.products} ORDER BY name
    ''');

    return _ReportDetails(
      sales: sales.map((r) => [r['id'].toString(), _date(r['date']), r['customer_name'].toString(), _moneyNum(r['subtotal']), _moneyNum(r['discount']), _moneyNum(r['total']), _moneyNum(r['paid_amount']), _moneyNum(r['remaining']), r['notes'].toString()]).toList(),
      purchases: purchases.map((r) => [r['id'].toString(), _date(r['date']), r['supplier_name'].toString(), _moneyNum(r['subtotal']), _moneyNum(r['discount']), _moneyNum(r['total']), _moneyNum(r['paid_amount']), _moneyNum(r['remaining']), r['notes'].toString()]).toList(),
      expenses: expenses.map((r) => [_date(r['date']), r['category'].toString(), r['account_name'].toString(), _moneyNum(r['amount']), r['notes'].toString()]).toList(),
      saleReturns: saleReturns.map((r) => [r['id'].toString(), _date(r['date']), r['sale_id'].toString(), r['customer_name'].toString(), _moneyNum(r['total']), _moneyNum(r['refunded_amount']), r['notes'].toString()]).toList(),
      purchaseReturns: purchaseReturns.map((r) => [r['id'].toString(), _date(r['date']), r['purchase_id'].toString(), r['supplier_name'].toString(), _moneyNum(r['total']), _moneyNum(r['refunded_amount']), r['notes'].toString()]).toList(),
      stock: stock.map((r) => [r['name'].toString(), r['barcode'].toString(), r['quantity'].toString(), r['min_quantity'].toString(), _moneyNum(r['purchase_price']), _moneyNum(r['selling_price']), _moneyNum(r['stock_value'])]).toList(),
    );
  }

  (DateTime, DateTime) _periodRange(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case 'اليوم': return (today, today.add(const Duration(days: 1)));
      case 'هذا الأسبوع':
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case 'آخر 3 شهور': return (DateTime(now.year, now.month - 2, 1), today.add(const Duration(days: 1)));
      case 'هذا العام': return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      default: return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    }
  }

  Future<Uint8List> _buildPdf(ReportSummary s, String period, String report, _ReportDetails details) async {
    final document = pw.Document();
    final font = await _loadOfflineArabicFont();

    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      build: (_) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('تقرير دفتر', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('الفترة: $period'),
              pw.Text('نوع التقرير: $report'),
              pw.SizedBox(height: 16),
              _pdfSummary(s),
              if (_includes(report, 'المبيعات')) ...[_pdfTitle('تفاصيل المبيعات'), _pdfDetailTable(['الفاتورة', 'التاريخ', 'العميل', 'الإجمالي', 'المدفوع', 'المتبقي'], details.sales.map((r) => [r[0], r[1], r[2], r[5], r[6], r[7]]).toList())],
              if (_includes(report, 'المشتريات')) ...[_pdfTitle('تفاصيل المشتريات'), _pdfDetailTable(['الفاتورة', 'التاريخ', 'المورد', 'الإجمالي', 'المدفوع', 'المتبقي'], details.purchases.map((r) => [r[0], r[1], r[2], r[5], r[6], r[7]]).toList())],
              if (_includes(report, 'المصروفات')) ...[_pdfTitle('تفاصيل المصروفات'), _pdfDetailTable(['التاريخ', 'المصروف', 'الحساب', 'المبلغ', 'ملاحظات'], details.expenses)],
              if (_includes(report, 'مرتجعات البيع')) ...[_pdfTitle('تفاصيل مرتجعات البيع'), _pdfDetailTable(['المرتجع', 'التاريخ', 'الفاتورة', 'العميل', 'الإجمالي', 'المسترد'], details.saleReturns.map((r) => [r[0], r[1], r[2], r[3], r[4], r[5]]).toList())],
              if (_includes(report, 'مرتجعات الشراء')) ...[_pdfTitle('تفاصيل مرتجعات الشراء'), _pdfDetailTable(['المرتجع', 'التاريخ', 'الفاتورة', 'المورد', 'الإجمالي', 'المسترد'], details.purchaseReturns.map((r) => [r[0], r[1], r[2], r[3], r[4], r[5]]).toList())],
              if (_includes(report, 'المخزون')) ...[_pdfTitle('تفاصيل المخزون'), _pdfDetailTable(['المنتج', 'الباركود', 'الكمية', 'الحد الأدنى', 'شراء', 'بيع', 'القيمة'], details.stock)],
            ],
          ),
        ),
      ],
    ));
    return document.save();
  }

  Future<pw.Font> _loadOfflineArabicFont() async {
    final data = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
    return pw.Font.ttf(data);
  }

  pw.Widget _pdfSummary(ReportSummary s) => _pdfDetailTable(
    ['البند', 'العدد', 'القيمة'],
    [
      ['المبيعات', '${s.salesCount}', _money(s.salesTotal)],
      ['مرتجعات البيع', '${s.salesReturnsCount}', _money(s.salesReturnsTotal)],
      ['صافي المبيعات', '', _money(s.netSales)],
      ['المشتريات', '${s.purchasesCount}', _money(s.purchasesTotal)],
      ['مرتجعات الشراء', '${s.purchaseReturnsCount}', _money(s.purchaseReturnsTotal)],
      ['صافي المشتريات', '', _money(s.netPurchases)],
      ['المصروفات', '${s.expensesCount}', _money(s.expensesTotal)],
      ['صافي الحركة', '', _money(s.net)],
      ['قيمة المخزون', '', _money(s.stockValue)],
    ],
  );

  pw.Widget _pdfTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
    child: pw.Text(title, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
  );

  pw.Widget _pdfDetailTable(List<String> headers, List<List<String>> rows) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    cellAlignment: pw.Alignment.centerRight,
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    border: pw.TableBorder.all(color: PdfColors.grey400),
    cellPadding: const pw.EdgeInsets.all(5),
  );

  String _date(Object? value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _moneyNum(Object? value) => ((value as num?)?.toDouble() ?? 0).toStringAsFixed(2);
  String _money(double value) => '${value.toStringAsFixed(2)} جنيه';
}

class _ReportDetails {
  final List<List<String>> sales;
  final List<List<String>> purchases;
  final List<List<String>> expenses;
  final List<List<String>> saleReturns;
  final List<List<String>> purchaseReturns;
  final List<List<String>> stock;

  const _ReportDetails({
    required this.sales,
    required this.purchases,
    required this.expenses,
    required this.saleReturns,
    required this.purchaseReturns,
    required this.stock,
  });
}
