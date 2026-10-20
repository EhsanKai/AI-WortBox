import 'dart:io';
import 'dart:typed_data';

import 'package:ai_wortbox/features/backup/data/backup_file_source.dart';
import 'package:ai_wortbox/features/backup/data/safety_backup_store.dart';

/// Safety copies in memory; can be told to fail.
class MemorySafetyStore implements SafetyBackupStore {
  final saved = <(DateTime, Uint8List)>[];
  bool failing = false;

  @override
  Future<void> save(Uint8List bytes, DateTime nowUtc) async {
    if (failing) throw const FileSystemException('disk full');
    saved.insert(0, (nowUtc, bytes));
  }

  @override
  Future<List<SafetyBackup>> list() async => [
    for (final (at, bytes) in saved)
      SafetyBackup(savedAt: at, read: () async => bytes),
  ];
}

/// Returns a fixed file, or null to simulate cancelling the picker.
class FakeBackupFileSource implements BackupFileSource {
  FakeBackupFileSource([this.bytes]);

  Uint8List? bytes;

  @override
  Future<Uint8List?> pick() async => bytes;
}
