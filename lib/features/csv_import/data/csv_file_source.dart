import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';

@immutable
class PickedCsvFile {
  const PickedCsvFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Lets the user choose a local file. Abstracted for tests.
abstract interface class CsvFileSource {
  /// The chosen file, or null if the user cancelled.
  Future<PickedCsvFile?> pick();
}

class FilePickerCsvFileSource implements CsvFileSource {
  const FilePickerCsvFileSource();

  @override
  Future<PickedCsvFile?> pick() async {
    // Any file type: some Android providers report CSV files with MIME types
    // that an extension filter would hide. The content is validated anyway.
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > AppConfig.maxCsvBytes) {
      throw const CsvFormatException(CsvFormatError.tooLarge);
    }
    return PickedCsvFile(name: file.name, bytes: await file.readAsBytes());
  }
}
