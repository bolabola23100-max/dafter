import 'package:dafter/features/reports/service/report_export_service.dart';
import 'package:dafter/features/reports/service/report_service.dart';
import 'package:flutter/material.dart';

class ExportPdfScreen extends StatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  State<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends State<ExportPdfScreen> {
  final _reportService = ReportService();
  final _exportService = ReportExportService();

  String selectedReport = 'كل التقارير';
  String selectedPeriod = 'هذا الشهر';
  bool _loading = false;

  final List<String> reports = const [
    'كل التقارير',
    'المبيعات',
    'المشتريات',
    'المصروفات',
    'الأرباح',
    'المخزون',
  ];

  final List<String> periods = const [
    'اليوم',
    'هذا الأسبوع',
    'هذا الشهر',
    'آخر 3 شهور',
    'هذا العام',
  ];

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
      default:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _loading = true);
    try {
      final range = _periodRange(selectedPeriod);
      final summary = await _reportService.getSummary(from: range.$1, to: range.$2);
      final saved = await _exportService.exportPdf(
        summary: summary,
        period: selectedPeriod,
        report: selectedReport,
      );
      if (!mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ ملف PDF بنجاح')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حصلت مشكلة وإحنا بنصدر التقرير')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _dropdown({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: _loading ? null : onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصدير PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 60),
                const SizedBox(height: 16),
                const Text('تصدير التقرير بصيغة PDF', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                _dropdown(title: 'نوع التقرير', value: selectedReport, items: reports, onChanged: (value) => setState(() => selectedReport = value!)),
                const SizedBox(height: 20),
                _dropdown(title: 'الفترة', value: selectedPeriod, items: periods, onChanged: (value) => setState(() => selectedPeriod = value!)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _exportPdf,
                  icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                  label: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(_loading ? 'جاري التصدير...' : 'حفظ PDF', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
