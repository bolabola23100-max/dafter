import 'package:dafter/core/backup/backup_service.dart';
import 'package:dafter/core/database/app_database.dart';
import 'package:dafter/features/sidebar/screens/sidebar_screen.dart';
import 'package:flutter/material.dart';

import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.database;
  // If the user has selected a backup folder, keep a daily SQLite backup there.
  await BackupService.instance.backupDatabase();

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
      home: SidebarScreen(),
    );
  }
}
