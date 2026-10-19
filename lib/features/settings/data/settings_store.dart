import '../../../core/error/app_exception.dart';
import '../../../data/database/app_database.dart';

/// Local, non-secret key-value settings in the app database
/// (`app_settings`). Secrets never go here: the AI key stays in OS secure
/// storage.
class SettingsStore {
  SettingsStore(this._db);

  final AppDatabase _db;

  Future<String?> read(String key) => _guard('settings.read', () async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  });

  /// Writes all [values] in one transaction (null deletes a key).
  Future<void> writeAll(Map<String, String?> values) =>
      _guard('settings.write', () {
        return _db.transaction(() async {
          for (final MapEntry(:key, :value) in values.entries) {
            if (value == null) {
              await (_db.delete(
                _db.appSettings,
              )..where((s) => s.key.equals(key))).go();
            } else {
              await _db
                  .into(_db.appSettings)
                  .insertOnConflictUpdate(
                    AppSettingsCompanion.insert(key: key, value: value),
                  );
            }
          }
        });
      });

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}
