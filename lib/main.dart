import 'package:dafter/core/backup/backup_service.dart';
import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/sidebar/screens/sidebar_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  await AppDatabase.instance.database;
  // A backup failure must never prevent the POS from starting. The user can
  // still create a backup explicitly from the close flow.
  try {
    await BackupService.instance.backupDatabase();
  } catch (_) {}

  runApp(const DafterApp());
}

class DafterApp extends StatefulWidget {
  const DafterApp({super.key});

  @override
  State<DafterApp> createState() => _DafterAppState();
}

class _DafterAppState extends State<DafterApp> with WindowListener {
  bool _showingCloseDialog = false;
  bool _closingWindow = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _closeWindow() async {
    if (_closingWindow) return;
    _closingWindow = true;

    // The native X button is intercepted by setPreventClose(true). Once the
    // user has confirmed, disable interception before forcing the window out.
    // This also prevents the close request from being trapped again.
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    if (_closingWindow || _showingCloseDialog) return;
    _showingCloseDialog = true;

    final result = await showDialog<_CloseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('قبل ما تقفل دفتر'),
        content: const Text('تحب تعمل نسخة احتياطية لبيانات المحل قبل ما تقفل البرنامج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _CloseAction.cancel),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _CloseAction.closeWithoutBackup),
            child: const Text('إغلاق بدون نسخة'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _CloseAction.backupAndClose),
            icon: const Icon(Icons.backup_outlined),
            label: const Text('نسخ احتياطي وإغلاق'),
          ),
        ],
      ),
    );

    _showingCloseDialog = false;
    if (!mounted || result == null || result == _CloseAction.cancel) return;

    if (result == _CloseAction.backupAndClose) {
      var directory = await BackupService.instance.getBackupDirectory();
      if (directory == null) {
        final selected = await BackupService.instance.chooseBackupDirectory();
        if (!selected) return;
        directory = await BackupService.instance.getBackupDirectory();
      }
      if (directory == null) return;

      try {
        final backup = await BackupService.instance.backupDatabase(force: true);
        if (backup == null) return;
      } catch (_) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('النسخ الاحتياطي فشل'),
              content: const Text(
                'مقدرتش أحفظ النسخة الاحتياطية، فالبرنامج مش هيتقفل عشان بياناتك تفضل آمنة.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تمام'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    await _closeWindow();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      home: const SidebarScreen(),
    );
  }
}

enum _CloseAction { cancel, closeWithoutBackup, backupAndClose }
