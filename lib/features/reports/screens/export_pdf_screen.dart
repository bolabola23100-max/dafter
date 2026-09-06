import 'package:flutter/material.dart';

class ExportPdfScreen extends StatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  State<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends State<ExportPdfScreen> {
  String selectedReport = 'كل التقارير';
  String selectedPeriod = 'هذا الشهر';

  final List<String> reports = [
    'كل التقارير',
    'المبيعات',
    'المشتريات',
    'المصروفات',
    'الأرباح',
    'المخزون',
  ];

  final List<String> periods = [
    'اليوم',
    'هذا الأسبوع',
    'هذا الشهر',
    'آخر 3 شهور',
    'هذا العام',
  ];

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'جاري تجهيز تقرير $selectedReport للفترة: $selectedPeriod',
        ),
      ),
    );
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
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
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
                const Text(
                  'تصدير التقرير بصيغة PDF',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                _dropdown(
                  title: 'نوع التقرير',
                  value: selectedReport,
                  items: reports,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedReport = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                _dropdown(
                  title: 'الفترة',
                  value: selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPeriod = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.download),
                  label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('تصدير PDF', style: TextStyle(fontSize: 16)),
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
