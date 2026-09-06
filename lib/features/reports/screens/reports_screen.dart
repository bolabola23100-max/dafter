import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/core/widgets/nav.dart';
import 'package:dafter/features/reports/screens/export_excel_screen.dart';
import 'package:dafter/features/reports/screens/export_pdf_screen.dart';
import 'package:dafter/features/reports/screens/full_report_screen.dart';
import 'package:dafter/features/reports/screens/report_filter_screen.dart';
import 'package:dafter/features/reports/widgets/reports_summary_row.dart';
import 'package:dafter/features/reports/widgets/reports_table.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedPeriod = 'هذا الشهر';
  String selectedReport = 'كل التقارير';

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

    _showSnackBar('تم تطبيق الفلتر: $selectedPeriod - $selectedReport');
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
          // =========================================================
          // Action Buttons
          // =========================================================
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'تصدير PDF',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const ExportPdfScreen());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.table_chart_outlined,
                  label: 'تصدير Excel',
                  primary: false,
                  onTap: () {
                    Nav.push(context, const ExportExcelScreen());
                  },
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
                  onTap: () {
                    Nav.push(context, const FullReportScreen());
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Summary Cards
          // =========================================================
          const ReportsSummaryRow(),

          const SizedBox(height: 24),

          // =========================================================
          // Report Header
          // =========================================================
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ملخص التقارير',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$selectedPeriod • $selectedReport',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =========================================================
          // Reports Table
          // =========================================================
          const Expanded(
            child: ReportsTable(),
          ),
        ],
      ),
    );
  }
}
