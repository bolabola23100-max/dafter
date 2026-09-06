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
    // Make sure a possible WAL is checkpointed before copying the database file.
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

    // Stop the watcher connection, close the main DB, replace the file, then
    // reopen both connections. Listeners remain registered in the watcher.
    await AppDatabaseWatcher.instance.stopConnection();
    await AppDatabase.instance.close();

    try {
      await source.copy(temp.path);
      await temp.copy(target.path);
      if (await temp.exists()) await temp.delete();
      await AppDatabase.instance.database;
      await AppDatabaseWatcher.instance.start();
      AppDatabaseWatcher.instance.notifyListeners();
      return true;
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      await AppDatabase.instance.database;
      await AppDatabaseWatcher.instance.start();
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
