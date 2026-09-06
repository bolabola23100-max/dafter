import 'package:dafter/core/backup/backup_service.dart';
import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/features/reports/service/report_export_service.dart';
import 'package:dafter/features/reports/service/report_service.dart';
import 'package:dafter/features/settings/widgets/settings_summary_row.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = BackupService.instance;
  final _reportService = ReportService();
  final _exportService = ReportExportService();

  String? _backupDirectory;
  String selectedPeriod = 'هذا الشهر';
  String selectedReport = 'كل التقارير';
  bool _loading = true;
  bool _backupLoading = false;
  bool _exportLoading = false;
  bool _restoreLoading = false;

  final periods = const ['اليوم', 'هذا الأسبوع', 'هذا الشهر', 'آخر 3 شهور', 'هذا العام'];
  final reports = const ['كل التقارير', 'المبيعات', 'المشتريات', 'المصروفات', 'صافي الحركة', 'المخزون'];

  @override
  void initState() {
    super.initState();
    _loadBackupDirectory();
  }

  Future<void> _loadBackupDirectory() async {
    final directory = await _backupService.getBackupDirectory();
    if (!mounted) return;
    setState(() {
      _backupDirectory = directory;
      _loading = false;
    });
  }

  Future<void> _chooseBackupDirectory() async {
    final selected = await _backupService.chooseBackupDirectory();
    if (!selected) return;
    await _loadBackupDirectory();
    if (mounted) _message('تم حفظ مكان النسخ الاحتياطي');
  }

  Future<void> _backupNow() async {
    setState(() => _backupLoading = true);
    try {
      var directory = await _backupService.getBackupDirectory();
      if (directory == null) {
        await _chooseBackupDirectory();
        directory = await _backupService.getBackupDirectory();
      }
      if (directory == null) return;
      final file = await _backupService.backupDatabase(force: true);
      if (mounted) _message(file == null ? 'مقدرتش أعمل النسخة الاحتياطية' : 'تم إنشاء النسخة الاحتياطية بنجاح');
    } catch (_) {
      if (mounted) _message('حصلت مشكلة أثناء إنشاء النسخة الاحتياطية');
    } finally {
      if (mounted) setState(() => _backupLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع نسخة احتياطية'),
        content: const Text('البيانات الحالية هتتستبدل بالنسخة اللي هتختارها. اتأكد إن عندك نسخة حديثة قبل الاسترجاع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('اختيار النسخة')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _restoreLoading = true);
    final restored = await _backupService.restoreDatabaseFromFile();
    if (!mounted) return;
    setState(() => _restoreLoading = false);
    _message(restored ? 'تم استرجاع البيانات بنجاح' : 'مقدرتش أسترجع النسخة الاحتياطية');
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

  Future<void> _export({required bool pdf}) async {
    setState(() => _exportLoading = true);
    try {
      final range = _periodRange(selectedPeriod);
      final summary = await _reportService.getSummary(from: range.$1, to: range.$2);
      final saved = pdf
          ? await _exportService.exportPdf(summary: summary, period: selectedPeriod, report: selectedReport)
          : await _exportService.exportExcel(summary: summary, period: selectedPeriod, report: selectedReport);
      if (mounted && saved) _message('تم حفظ ${pdf ? 'PDF' : 'Excel'} بالتفاصيل بنجاح');
    } catch (_) {
      if (mounted) _message('حصلت مشكلة أثناء التصدير');
    } finally {
      if (mounted) setState(() => _exportLoading = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('التصدير والنسخ الاحتياطي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('من هنا بس هتعمل تصدير التقارير وتحفظ أو تسترجع بيانات المحل.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('تصدير التقارير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(initialValue: selectedReport, decoration: const InputDecoration(labelText: 'نوع التقرير'), items: reports.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: _exportLoading ? null : (v) { if (v != null) setState(() => selectedReport = v); })),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(initialValue: selectedPeriod, decoration: const InputDecoration(labelText: 'الفترة'), items: periods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: _exportLoading ? null : (v) { if (v != null) setState(() => selectedPeriod = v); })),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: ActionButton(icon: Icons.picture_as_pdf_outlined, label: _exportLoading ? 'جاري التصدير...' : 'تصدير PDF بالتفاصيل', primary: false, onTap: _exportLoading ? () {} : () => _export(pdf: true))),
                    const SizedBox(width: 12),
                    Expanded(child: ActionButton(icon: Icons.table_chart_outlined, label: _exportLoading ? 'جاري التصدير...' : 'تصدير Excel بالتفاصيل', primary: true, onTap: _exportLoading ? () {} : () => _export(pdf: false))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E9EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('النسخ الاحتياطي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('النسخة دي فيها قاعدة بيانات المحل كاملة: المنتجات، المبيعات، المشتريات، العملاء، الموردين، الحسابات والمصروفات.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: ActionButton(icon: Icons.folder_outlined, label: 'اختيار مكان النسخ', primary: true, onTap: _chooseBackupDirectory)),
                    const SizedBox(width: 12),
                    Expanded(child: ActionButton(icon: Icons.backup_outlined, label: _backupLoading ? 'جاري النسخ...' : 'نسخ احتياطي الآن', primary: false, onTap: _backupLoading ? () {} : _backupNow)),
                    const SizedBox(width: 12),
                    Expanded(child: ActionButton(icon: Icons.restore_outlined, label: _restoreLoading ? 'جاري الاسترجاع...' : 'استرجاع نسخة', primary: false, onTap: _restoreLoading ? () {} : _restoreBackup)),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.folder_open_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('مكان حفظ النسخ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_loading ? 'جاري التحميل...' : _backupDirectory ?? 'لسه مفيش مكان محدد', style: const TextStyle(color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SettingsSummaryRow(),
          ],
        ),
      ),
    );
  }
}
