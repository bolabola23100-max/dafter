import 'package:dafter/core/backup/backup_service.dart';
import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/features/settings/widgets/settings_summary_row.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _backupDirectory;
  bool _loading = true;
  bool _backupLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupDirectory();
  }

  Future<void> _loadBackupDirectory() async {
    final directory = await BackupService.instance.getBackupDirectory();
    if (!mounted) return;
    setState(() {
      _backupDirectory = directory;
      _loading = false;
    });
  }

  Future<void> _chooseBackupDirectory() async {
    final selected = await BackupService.instance.chooseBackupDirectory();
    if (!selected) return;
    await _loadBackupDirectory();
    if (!mounted) return;
    _message('تم حفظ مكان النسخ الاحتياطي');
  }

  Future<void> _backupNow() async {
    setState(() => _backupLoading = true);
    try {
      final file = await BackupService.instance.backupDatabase(force: true);
      if (!mounted) return;
      _message(
        file == null
            ? 'اختار مكان النسخ الاحتياطي الأول'
            : 'تم إنشاء النسخة الاحتياطية بنجاح',
      );
    } catch (_) {
      if (!mounted) return;
      _message('حصلت مشكلة أثناء إنشاء النسخة الاحتياطية');
    } finally {
      if (mounted) setState(() => _backupLoading = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: Icons.folder_outlined,
                    label: 'اختيار مكان النسخ',
                    primary: true,
                    onTap: _loading ? null : _chooseBackupDirectory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.backup_outlined,
                    label: _backupLoading ? 'جاري النسخ...' : 'نسخ احتياطي الآن',
                    primary: false,
                    onTap: _backupLoading ? null : _backupNow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.restore_outlined,
                    label: 'استعادة',
                    primary: false,
                    onTap: () => _message('الاستعادة تحتاج تأكيد واستبدال قاعدة البيانات الحالية، وهنضيفها بشكل آمن قبل التسليم.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E9EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مكان النسخ الاحتياطي', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(
                          _loading
                              ? 'جاري التحميل...'
                              : _backupDirectory ?? 'لسه مفيش مكان محدد',
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
