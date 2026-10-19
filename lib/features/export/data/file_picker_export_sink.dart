import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../domain/export_file_sink.dart';

/// [ExportFileSink] using `file_picker`'s save dialog, which writes the
/// bytes to the location the user chooses.
class FilePickerExportSink implements ExportFileSink {
  const FilePickerExportSink();

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      return uri != null;
    } on Object {
      throw const ExportException(ExportError.writeFailed);
    }
  }
}
