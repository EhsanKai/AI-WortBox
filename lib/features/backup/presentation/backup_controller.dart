import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../about/domain/release_notes.dart';
import '../../about/presentation/about_providers.dart';
import '../../export/domain/export_file_sink.dart';
import '../data/backup_codec.dart';
import '../data/backup_service.dart';
import '../data/safety_backup_store.dart';

/// Where the backup screen is.
sealed class BackupState {
  const BackupState();
}

final class BackupIdle extends BackupState {
  const BackupIdle({this.saved = false});

  /// A backup file was just saved.
  final bool saved;
}

/// Saving, reading or restoring.
final class BackupBusy extends BackupState {
  const BackupBusy(this.task);

  final BackupTask task;
}

enum BackupTask { saving, reading, restoring }

/// A valid backup was chosen; nothing has been written yet.
final class BackupPreview extends BackupState {
  const BackupPreview({
    required this.backup,
    required this.current,
    this.fromSafetyCopy = false,
  });

  final ValidatedBackup backup;

  /// What is on the device now.
  final BackupCounts current;

  /// The file is a safety copy made before an earlier restore.
  final bool fromSafetyCopy;
}

final class BackupRestored extends BackupState {
  const BackupRestored(this.result);

  final RestoreResult result;
}

final class BackupFailed extends BackupState {
  const BackupFailed(this.error);

  /// An [AppException] (shown with its localized message) or anything else.
  final Object error;
}

class BackupController extends Notifier<BackupState> {
  @override
  BackupState build() => const BackupIdle();

  BackupService get _service => ref.read(backupServiceProvider);

  /// Creates a backup of the current data and lets the user save it.
  Future<void> save() async {
    state = const BackupBusy(BackupTask.saving);
    try {
      final app = await _installed();
      final bytes = await _service.createBackup(app: app);
      final clock = ref.read(clockProvider);
      final saved = await ref
          .read(exportFileSinkProvider)
          .save(
            fileName: exportFileName(
              'backup',
              clock.toLocal(clock.nowUtc()),
              'json',
            ),
            bytes: bytes,
            mimeType: 'application/json',
          );
      state = BackupIdle(saved: saved);
    } on Object catch (e) {
      state = BackupFailed(e);
    }
  }

  /// Lets the user choose a file and validates it.
  Future<void> pick() async {
    state = const BackupBusy(BackupTask.reading);
    try {
      final bytes = await ref.read(backupFileSourceProvider).pick();
      if (bytes == null) {
        state = const BackupIdle();
        return;
      }
      await _preview(bytes);
    } on Object catch (e) {
      state = BackupFailed(e);
    }
  }

  /// Opens [copy] (made before an earlier restore) for restoring.
  Future<void> openSafetyCopy(SafetyBackup copy) async {
    state = const BackupBusy(BackupTask.reading);
    try {
      await _preview(await copy.read(), fromSafetyCopy: true);
    } on Object catch (e) {
      state = BackupFailed(e);
    }
  }

  Future<void> _preview(Uint8List bytes, {bool fromSafetyCopy = false}) async {
    final backup = await _service.read(bytes);
    state = BackupPreview(
      backup: backup,
      current: await _service.currentCounts(),
      fromSafetyCopy: fromSafetyCopy,
    );
  }

  /// Restores the previewed backup. Only after the user chose [mode] (and,
  /// for replace, confirmed it).
  Future<void> restore(RestoreMode mode) async {
    final preview = state;
    if (preview is! BackupPreview) return;
    state = const BackupBusy(BackupTask.restoring);
    try {
      final result = await _service.restore(
        preview.backup,
        mode,
        app: await _installed(),
      );
      ref.invalidate(safetyBackupsProvider);
      state = BackupRestored(result);
    } on Object catch (e) {
      ref.invalidate(safetyBackupsProvider);
      state = BackupFailed(e);
    }
  }

  void reset() => state = const BackupIdle();

  /// Version metadata for the file; a backup is still made without it.
  Future<InstalledVersion?> _installed() async {
    try {
      return await ref.read(installedVersionProvider.future);
    } on Object {
      return null;
    }
  }
}

final backupControllerProvider =
    NotifierProvider.autoDispose<BackupController, BackupState>(
      BackupController.new,
    );

/// Safety copies on the device, newest first.
final safetyBackupsProvider = FutureProvider.autoDispose<List<SafetyBackup>>(
  (ref) => ref.watch(safetyBackupStoreProvider).list(),
);
