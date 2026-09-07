import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';
import '../database/app_database_watcher.dart';

class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  Future<String?> getBackupDirectory() async {
    final file = File(
      p.join(await getDatabasesPath(), 'dafter_backup_settings.json'),
    );
    if (!await file.exists()) return null;

    try {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final path = data['directory'] as String?;
      if (path == null || path.trim().isEmpty) return null;
      return Directory(path).existsSync() ? path : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> chooseBackupDirectory() async {
    final directory = await getDirectoryPath(
      confirmButtonText: 'اختيار المجلد',
    );
    if (directory == null) return false;
    await _saveDirectory(directory);
    return true;
  }

  Future<File?> backupDatabase({bool force = false}) async {
    final directory = await getBackupDirectory();
    if (directory == null) return null;

    final db = await AppDatabase.instance.database;
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}

    final sourcePath = p.join(await getDatabasesPath(), 'dafter.db');
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final now = DateTime.now();
    final backupPath = p.join(directory, 'dafter_backup_${_stamp(now)}.db');
    final todayPath = p.join(directory, 'dafter_backup_${_date(now)}.db');

    if (!force && await File(todayPath).exists()) return File(todayPath);

    final target = File(backupPath);
    await source.copy(target.path);
    if (backupPath != todayPath) {
      await target.copy(todayPath);
      await target.delete();
    }
    return File(todayPath);
  }

  Future<bool> restoreDatabaseFromFile() async {
    const typeGroup = XTypeGroup(label: 'نسخة دفتر', extensions: ['db']);
    final location = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (location == null) return false;

    final source = File(location.path);
    if (!await source.exists()) return false;

    final databaseDirectory = await getDatabasesPath();
    final target = File(p.join(databaseDirectory, 'dafter.db'));
    final temp = File(p.join(databaseDirectory, 'dafter_restore_temp.db'));
    final old = File(p.join(databaseDirectory, 'dafter_restore_old.db'));

    // Validate the imported file before replacing the live database, and keep
    // a copy of the old database so a failed replacement can be rolled back.
    Database? validationDatabase;
    await AppDatabaseWatcher.instance.stopConnection();
    await AppDatabase.instance.close();

    try {
      if (await temp.exists()) await temp.delete();
      if (await old.exists()) await old.delete();

      await source.copy(temp.path);
      validationDatabase = await databaseFactoryFfi.openDatabase(
        temp.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );

      final requiredTables = <String>{
        'products',
        'sales',
        'sale_items',
        'purchases',
        'purchase_items',
      };
      final rows = await validationDatabase.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = rows
          .map((row) => row['name'] as String?)
          .whereType<String>()
          .toSet();
      if (!requiredTables.every(tableNames.contains)) {
        throw Exception('ملف النسخة الاحتياطية غير صالح');
      }

      await validationDatabase.close();
      validationDatabase = null;

      if (await target.exists()) {
        await target.copy(old.path);
      }
      await temp.copy(target.path);
      await temp.delete();

      // Opening the replaced file is the final validation. If this fails,
      // restore the previous database instead of leaving a broken DB behind.
      await AppDatabase.instance.database;
      if (await old.exists()) await old.delete();

      await AppDatabaseWatcher.instance.start();
      AppDatabaseWatcher.instance.notifyListeners();
      return true;
    } catch (_) {
      await validationDatabase?.close();
      validationDatabase = null;

      if (await temp.exists()) await temp.delete();

      try {
        await AppDatabase.instance.close();
      } catch (_) {}

      if (await old.exists()) {
        try {
          await old.copy(target.path);
          await old.delete();
        } catch (_) {}
      }

      try {
        await AppDatabase.instance.database;
        await AppDatabaseWatcher.instance.start();
      } catch (_) {}
      return false;
    }
  }

  Future<void> _saveDirectory(String directory) async {
    final settingsPath = p.join(
      await getDatabasesPath(),
      'dafter_backup_settings.json',
    );
    await File(
      settingsPath,
    ).writeAsString(jsonEncode({'directory': directory}), flush: true);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _stamp(DateTime value) =>
      '${_date(value)}_${value.hour.toString().padLeft(2, '0')}-${value.minute.toString().padLeft(2, '0')}-${value.second.toString().padLeft(2, '0')}';
}
