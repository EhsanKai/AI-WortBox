import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';

/// Lets the user choose a backup file. Abstracted for tests.
abstract interface class BackupFileSource {
  /// The chosen file's bytes, or null if the user cancelled. Throws
  /// `BackupException(tooLarge)` above [AppConfig.maxBackupBytes].
  Future<Uint8List?> pick();
}

class FilePickerBackupFileSource implements BackupFileSource {
  const FilePickerBackupFileSource();

  @override
  Future<Uint8List?> pick() async {
    // Any type: some file providers report JSON with other MIME types. The
    // content is validated anyway.
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > AppConfig.maxBackupBytes) {
      throw const BackupException(BackupError.tooLarge);
    }
    return file.readAsBytes();
  }
}
