import 'dart:typed_data';

/// Lets the user save a file with the platform's own save dialog
/// (Android: Storage Access Framework; iOS: document picker).
abstract interface class ExportFileSink {
  /// Saves [bytes] as [fileName]. Returns false when the user cancelled.
  /// Throws `ExportException(writeFailed)` when the file cannot be written.
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

/// A file name for [deckName] and [extension]: characters that are invalid
/// in file names are replaced, Persian and German letters are kept.
String exportFileName(String deckName, DateTime localDate, String extension) {
  final safe = deckName
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final date =
      '${localDate.year.toString().padLeft(4, '0')}-'
      '${localDate.month.toString().padLeft(2, '0')}-'
      '${localDate.day.toString().padLeft(2, '0')}';
  final base = safe.isEmpty ? 'AI WortBox' : 'AI WortBox - $safe';
  return '$base - $date.$extension';
}
