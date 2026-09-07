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
    final file = File(p.join(await getDatabasesPath(), 'dafter_backup_settings.json'));
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final path = data['directory'] as String?;
      if (path == null || path.trim().isEmpty) return null;
      return Directory(path).existsSync() ? path : null;
    } catch (_) { return null; }
  }

  Future<bool> chooseBackupDirectory() async {
    final directory = await getDirectoryPath(confirmButtonText: 'اختيار المجلد');
    if (directory == null) return false;
    await _saveDirectory(directory);
    return true;
  }

  Future<File?> backupDatabase({bool force = false}) async {
    final directory = await getBackupDirectory();
    if (directory == null) return null;
    final db = await AppDatabase.instance.database;
    try { await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)'); } catch (_) {}

    final source = File(p.join(await getDatabasesPath(), 'dafter.db'));
    if (!await source.exists()) return null;
    final now = DateTime.now();
    final todayPath = p.join(directory, 'dafter_backup_${_date(now)}.db');
    if (!force && await File(todayPath).exists()) return File(todayPath);

    final temp = File(p.join(directory, '.dafter_backup_${_stamp(now)}.tmp'));
    try {
      await source.copy(temp.path);
      await _validateDatabaseFile(temp.path);
      await temp.copy(todayPath);
      return File(todayPath);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
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

    // Never replace the live database with an unvalidated file.
    try {
      if (await temp.exists()) await temp.delete();
      await source.copy(temp.path);
      await _validateDatabaseFile(temp.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      return false;
    }

    await AppDatabaseWatcher.instance.stopConnection();
    await AppDatabase.instance.close();
    try {
      if (await old.exists()) await old.delete();
      if (await target.exists()) await target.copy(old.path);
      await temp.copy(target.path);
      await temp.delete();

      await AppDatabase.instance.database;
      await AppDatabaseWatcher.instance.start();
      AppDatabaseWatcher.instance.notifyListeners();
      if (await old.exists()) await old.delete();
      return true;
    } catch (_) {
      try { await AppDatabase.instance.close(); } catch (_) {}
      if (await temp.exists()) await temp.delete();
      if (await old.exists()) {
        try { await old.copy(target.path); } catch (_) {}
        try { await old.delete(); } catch (_) {}
      }
      try {
        await AppDatabase.instance.database;
        await AppDatabaseWatcher.instance.start();
        AppDatabaseWatcher.instance.notifyListeners();
      } catch (_) {}
      return false;
    }
  }

  Future<void> _validateDatabaseFile(String path) async {
    final database = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
    try {
      final integrity = await database.rawQuery('PRAGMA integrity_check');
      if (integrity.isEmpty || integrity.first.values.first.toString().toLowerCase() != 'ok') throw Exception('نسخة قاعدة البيانات تالفة');
      final rows = await database.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('products','sales','sale_items','purchases','purchase_items')");
      if (rows.length < 5) throw Exception('نسخة قاعدة البيانات غير صالحة');
    } finally { await database.close(); }
  }

  Future<void> _saveDirectory(String directory) async {
    final settingsPath = p.join(await getDatabasesPath(), 'dafter_backup_settings.json');
    await File(settingsPath).writeAsString(jsonEncode({'directory': directory}), flush: true);
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _stamp(DateTime value) => '${_date(value)}_${value.hour.toString().padLeft(2, '0')}-${value.minute.toString().padLeft(2, '0')}-${value.second.toString().padLeft(2, '0')}';
}
