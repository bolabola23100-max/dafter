import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/sidebar/screens/sidebar_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // bolaGpt1 is intentionally UI/UX-only. AppDatabase uses an in-memory
  // database on this branch, so experiments never persist shop data to disk.
  await AppDatabase.instance.database;

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
          content: const Text('تحب تعمل نسخة احتياطية لبيانات المحل قبل ما تقفل البرنامج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _CloseAction.cancel),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _CloseAction.backupAndClose),
              icon: const Icon(Icons.backup_outlined),
              label: const Text('نسخ احتياطي وإغلاق'),
            ),
          ],
        ),
      );

      // UI-only branch: the backup/close option simply closes. No shop data
      // is persisted by this branch because its database is in-memory.
      if (!mounted || result == null || result == _CloseAction.cancel) return;
      await _closeWindow();
    } finally {
      _showingCloseDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _CloseAction { cancel, backupAndClose }
