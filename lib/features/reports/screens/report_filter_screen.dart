import 'package:flutter/material.dart';

class ReportFilterScreen extends StatefulWidget {
  final String initialPeriod;
  final String initialReport;

  const ReportFilterScreen({
    super.key,
    this.initialPeriod = 'هذا الشهر',
    this.initialReport = 'كل التقارير',
  });

  @override
  State<ReportFilterScreen> createState() => _ReportFilterScreenState();
}

class _ReportFilterScreenState extends State<ReportFilterScreen> {
  late String selectedPeriod;
  late String selectedReport;

  final List<String> periods = [
    'اليوم',
    'هذا الأسبوع',
    'هذا الشهر',
    'آخر 3 شهور',
    'هذا العام',
  ];

  final List<String> reports = [
    'كل التقارير',
    'المبيعات',
    'المشتريات',
    'المصروفات',
    'صافي الحركة',
    'المخزون',
  ];

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.initialPeriod;
    selectedReport = widget.initialReport == 'الأرباح' ? 'صافي الحركة' : widget.initialReport;
  }

  void _applyFilter() {
    Navigator.pop(context, {
      'period': selectedPeriod,
      'report': selectedReport,
    });
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
          initialValue: items.contains(value) ? value : items.first,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصفية التقارير')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.filter_alt_outlined, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'تصفية التقارير',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                _dropdown(
                  title: 'الفترة',
                  value: selectedPeriod,
                  items: periods,
                  onChanged: (value) {
                    if (value != null) setState(() => selectedPeriod = value);
                  },
                ),
                const SizedBox(height: 20),
                _dropdown(
                  title: 'نوع التقرير',
                  value: selectedReport,
                  items: reports,
                  onChanged: (value) {
                    if (value != null) setState(() => selectedReport = value);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _applyFilter,
                  icon: const Icon(Icons.check),
                  label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('تطبيق التصفية', style: TextStyle(fontSize: 16)),
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
