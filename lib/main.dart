import 'package:dafter/features/sidebar/screens/sidebar_screen.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';

import 'package:dafter/core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: SidebarScreen(),
    );
  }
}
