import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/reports/model/report_summary.dart';
import 'package:dafter/features/reports/screens/export_excel_screen.dart';
import 'package:dafter/features/reports/screens/export_pdf_screen.dart';
import 'package:dafter/features/reports/screens/full_report_screen.dart';
import 'package:dafter/features/reports/screens/report_filter_screen.dart';
import 'package:dafter/features/reports/service/report_service.dart';
import 'package:dafter/features/reports/widgets/reports_summary_row.dart';
import 'package:dafter/features/reports/widgets/reports_table.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();

  String selectedPeriod = 'هذا الشهر';
  String selectedReport = 'كل التقارير';
  ReportSummary _summary = const ReportSummary();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final range = _periodRange(selectedPeriod);
      final summary = await _reportService.getSummary(
        from: range.$1,
        to: range.$2,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('حصلت مشكلة وإحنا بنجيب التقرير');
    }
  }

  (DateTime, DateTime) _periodRange(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'اليوم':
        return (today, today.add(const Duration(days: 1)));
      case 'هذا الأسبوع':
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case 'آخر 3 شهور':
        return (DateTime(now.year, now.month - 2, 1), today.add(const Duration(days: 1)));
      case 'هذا العام':
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      case 'هذا الشهر':
      default:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    }
  }

  Future<void> _openFilter() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportFilterScreen(
          initialPeriod: selectedPeriod,
          initialReport: selectedReport,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      selectedPeriod = result['period'] ?? selectedPeriod;
      selectedReport = result['report'] ?? selectedReport;
    });
    await _loadReport();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'تصدير PDF',
                  primary: false,
                  onTap: () => Nav.push(context, const ExportPdfScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.table_chart_outlined,
                  label: 'تصدير Excel',
                  primary: false,
                  onTap: () => Nav.push(context, const ExportExcelScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.filter_list_outlined,
                  label: 'تصفية',
                  primary: false,
                  onTap: _openFilter,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.bar_chart_outlined,
                  label: 'تقرير شامل',
                  primary: true,
                  onTap: () => Nav.push(context, const FullReportScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ReportsSummaryRow(
              totalRevenue: _summary.netSales,
              totalExpenses: _summary.expensesTotal,
              netProfit: _summary.net,
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ملخص التقارير',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedPeriod • $selectedReport',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ReportsTable(
                    salesCount: _summary.salesCount,
                    salesTotal: _summary.salesTotal,
                    purchasesCount: _summary.purchasesCount,
                    purchasesTotal: _summary.purchasesTotal,
                    expensesCount: _summary.expensesCount,
                    expensesTotal: _summary.expensesTotal,
                    salesReturnsCount: _summary.salesReturnsCount,
                    salesReturnsTotal: _summary.salesReturnsTotal,
                    purchaseReturnsCount: _summary.purchaseReturnsCount,
                    purchaseReturnsTotal: _summary.purchaseReturnsTotal,
                    stockValue: _summary.stockValue,
                  ),
          ),
        ],
      ),
    );
  }
}
