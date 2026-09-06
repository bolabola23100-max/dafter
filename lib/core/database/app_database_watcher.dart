import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_database.dart';

/// Watches a second SQLite connection for committed database changes.
class AppDatabaseWatcher {
  AppDatabaseWatcher._();

  static final AppDatabaseWatcher instance = AppDatabaseWatcher._();

  Database? _watchDatabase;
  Timer? _timer;
  int? _lastVersion;
  bool _starting = false;
  bool _checking = false;

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  Future<void> start() async {
    if (_timer != null || _starting) return;
    _starting = true;

    try {
      final mainDatabase = await AppDatabase.instance.database;
      final rows = await mainDatabase.rawQuery('PRAGMA database_list');
      final databasePath =
          rows.firstWhere(
                (row) => row['name'] == 'main',
                orElse: () => <String, Object?>{},
              )['file']
              as String?;

      if (databasePath == null || databasePath.isEmpty) return;

      _watchDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );

      _lastVersion = await _readVersion();
      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _checkForChanges(),
      );
    } finally {
      _starting = false;
    }
  }

  /// Closes only the watcher connection while keeping listeners registered.
  Future<void> stopConnection() async {
    _timer?.cancel();
    _timer = null;
    final database = _watchDatabase;
    _watchDatabase = null;
    if (database != null) await database.close();
  }

  void notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  Future<int?> _readVersion() async {
    final database = _watchDatabase;
    if (database == null) return null;
    try {
      final rows = await database.rawQuery('PRAGMA data_version');
      if (rows.isEmpty) return null;
      return (rows.first.values.first as num).toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkForChanges() async {
    if (_checking) return;
    _checking = true;
    try {
      final currentVersion = await _readVersion();
      if (currentVersion == null) return;
      if (_lastVersion == null) {
        _lastVersion = currentVersion;
        return;
      }
      if (currentVersion != _lastVersion) {
        _lastVersion = currentVersion;
        notifyListeners();
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> dispose() async {
    await stopConnection();
    _listeners.clear();
  }
}

typedef VoidCallback = void Function();
