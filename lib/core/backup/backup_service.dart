import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

    final sourcePath = p.join(await getDatabasesPath(), 'dafter.db');
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final now = DateTime.now();
    final stamp = _stamp(now);
    final backupPath = p.join(directory, 'dafter_backup_$stamp.db');
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
