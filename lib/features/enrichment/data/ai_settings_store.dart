import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/error/app_exception.dart';

/// Where the user's own OpenRouter key and model choice are kept.
///
/// The key is never stored in SQLite, preferences, logs or backups.
abstract interface class AiSettingsStore {
  Future<String?> readApiKey();

  /// Replaces any saved key.
  Future<void> writeApiKey(String apiKey);

  Future<void> deleteApiKey();

  Future<String?> readModel();

  Future<void> writeModel(String modelId);
}

/// OS-backed secure storage: the iOS Keychain and, on Android, values
/// encrypted with AES-GCM under a key protected by the Android Keystore
/// (`flutter_secure_storage` defaults).
///
/// - iOS: `unlocked_this_device` — readable only while the device is
///   unlocked, never synced to iCloud Keychain or restored to another
///   device from a backup.
/// - Android: the storage files are excluded from Auto Backup and device
///   transfer (`res/xml/backup_rules.xml`, `data_extraction_rules.xml`).
///
/// The model id is not secret; it is kept here only to avoid adding a second
/// storage mechanism.
class SecureAiSettingsStore implements AiSettingsStore {
  SecureAiSettingsStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );

  static const _apiKey = 'openrouter_api_key';
  static const _model = 'openrouter_model';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readApiKey() =>
      _guard('read', () => _storage.read(key: _apiKey));

  @override
  Future<void> writeApiKey(String apiKey) =>
      _guard('write', () => _storage.write(key: _apiKey, value: apiKey));

  @override
  Future<void> deleteApiKey() =>
      _guard('delete', () => _storage.delete(key: _apiKey));

  @override
  Future<String?> readModel() =>
      _guard('read', () => _storage.read(key: _model));

  @override
  Future<void> writeModel(String modelId) =>
      _guard('write', () => _storage.write(key: _model, value: modelId));

  /// Platform errors are reported by code only: their messages could, in
  /// theory, echo a value.
  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on PlatformException catch (e) {
      throw StorageException('secureStorage.$operation', e.code);
    }
  }
}
