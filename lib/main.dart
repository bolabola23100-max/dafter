import 'package:dafter/core/backup/backup_service.dart';
import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/sidebar/screens/sidebar_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  await AppDatabase.instance.database;
  // A backup failure must never prevent the POS from starting. The user can
  // still create a backup explicitly from the close flow.
  try {
    await BackupService.instance.backupDatabase();
  } catch (_) {}

  runApp(const DafterApp());
}

class DafterApp extends StatelessWidget {
  const DafterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      home: const _WindowCloseHandler(child: SidebarScreen()),
    );
  }
}

/// Lives below MaterialApp so that its [BuildContext] has MaterialLocalizations
/// when the native Windows close event asks us to show an AlertDialog.
class _WindowCloseHandler extends StatefulWidget {
  const _WindowCloseHandler({required this.child});

  final Widget child;

  @override
  State<_WindowCloseHandler> createState() => _WindowCloseHandlerState();
}

class _WindowCloseHandlerState extends State<_WindowCloseHandler>
    with WindowListener {
  bool _showingCloseDialog = false;
  bool _closingWindow = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Wait until this widget is mounted below MaterialApp before intercepting
    // the native Windows X. This gives showDialog a fully initialized
    // Material/Localizations context when onWindowClose fires.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureWindowClose();
    });
  }

  Future<void> _configureWindowClose() async {
    if (!mounted) return;
    await windowManager.setClosable(true);
    await windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _closeWindow() async {
    if (_closingWindow) return;
    _closingWindow = true;

    // Disable interception before closing so the native close can complete.
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    if (_closingWindow || _showingCloseDialog) return;
    _showingCloseDialog = true;
    _handleWindowClose();
  }

  Future<void> _handleWindowClose() async {
    try {
      if (!mounted) return;

      final result = await showDialog<_CloseAction>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('قبل ما تقفل دفتر'),
          content: const Text(
            'تحب تعمل نسخة احتياطية لبيانات المحل قبل ما تقفل البرنامج؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _CloseAction.cancel),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, _CloseAction.backupAndClose),
              icon: const Icon(Icons.backup_outlined),
              label: const Text('نسخ احتياطي وإغلاق'),
            ),
          ],
        ),
      );

      if (!mounted || result == null || result == _CloseAction.cancel) return;

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
            barrierDismissible: false,
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

      await _closeWindow();
    } finally {
      _showingCloseDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _CloseAction { cancel, backupAndClose }
