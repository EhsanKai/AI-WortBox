import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';

/// A safety copy of the data, saved automatically before a restore.
@immutable
class SafetyBackup {
  const SafetyBackup({required this.savedAt, required this.read});

  /// UTC.
  final DateTime savedAt;

  /// The backup file's bytes.
  final Future<Uint8List> Function() read;
}

/// Keeps the newest [AppConfig.safetyBackupsKept] safety copies on the
/// device. They never leave the device.
abstract interface class SafetyBackupStore {
  /// Saves [bytes] as the newest copy and removes the oldest beyond the
  /// limit. Throws when the file cannot be written.
  Future<void> save(Uint8List bytes, DateTime nowUtc);

  /// Saved copies, newest first.
  Future<List<SafetyBackup>> list();
}

/// Safety copies in the app's private support directory
/// (`safety_backups/`), included in the device's own backup like the
/// database itself.
class FileSafetyBackupStore implements SafetyBackupStore {
  FileSafetyBackupStore({Future<Directory> Function()? baseDirectory})
    : _base = baseDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _base;

  static final _name = RegExp(r'^safety-(\d{8}T\d{6}\d{3})Z\.json$');

  Future<Directory> _dir() async {
    final dir = Directory('${(await _base()).path}/safety_backups');
    await dir.create(recursive: true);
    return dir;
  }

  static String _stamp(DateTime utc) {
    String two(int v, [int width = 2]) => v.toString().padLeft(width, '0');
    return '${two(utc.year, 4)}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}'
        '${two(utc.millisecond, 3)}';
  }

  static DateTime? _parse(String stamp) {
    final s = stamp;
    return DateTime.tryParse(
      '${s.substring(0, 8)}T${s.substring(9, 15)}.${s.substring(15)}Z',
    );
  }

  @override
  Future<void> save(Uint8List bytes, DateTime nowUtc) async {
    final dir = await _dir();
    final file = File('${dir.path}/safety-${_stamp(nowUtc.toUtc())}Z.json');
    // Written completely under a temporary name first, so a copy is never
    // half-written.
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
    final all = await _files(dir);
    for (final old in all.skip(AppConfig.safetyBackupsKept)) {
      await old.$2.delete();
    }
  }

  @override
  Future<List<SafetyBackup>> list() async => [
    for (final (savedAt, file) in await _files(await _dir()))
      SafetyBackup(savedAt: savedAt, read: file.readAsBytes),
  ];

  Future<List<(DateTime, File)>> _files(Directory dir) async {
    final result = <(DateTime, File)>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final match = _name.firstMatch(entity.uri.pathSegments.last);
      final at = match == null ? null : _parse(match[1]!);
      if (at != null) result.add((at, entity));
    }
    result.sort((a, b) => b.$1.compareTo(a.$1));
    return result;
  }
}
