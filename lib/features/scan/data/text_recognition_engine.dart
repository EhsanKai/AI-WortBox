import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/error/app_exception.dart';
import '../domain/scan_text.dart';
import 'scan_image_source.dart';

/// On-device text recognition. Abstracted so the engine can be replaced and
/// tests can use a fake.
abstract interface class TextRecognitionEngine {
  /// Whether recognition can run on this platform at all.
  bool get isAvailable;

  /// Recognizes the text in [image]. Throws [ScanException].
  Future<ScanText> recognize(PickedImage image);

  Future<void> dispose();
}

/// Google ML Kit text recognition with the bundled Latin-script model, which
/// covers German. Runs fully on the device; no network is used.
class MlKitTextRecognitionEngine implements TextRecognitionEngine {
  TextRecognizer? _recognizer;

  @override
  bool get isAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<ScanText> recognize(PickedImage image) async {
    if (!isAvailable) throw const ScanException(ScanError.ocrUnavailable);
    final recognizer = _recognizer ??= TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      return ScanText.fromRecognizedBlocks([
        for (final block in result.blocks)
          [for (final line in block.lines) (line.text, line.boundingBox)],
      ], rawText: result.text);
    } on PlatformException catch (e) {
      throw ScanException(ScanError.ocrFailed, e);
    } on MissingPluginException catch (e) {
      throw ScanException(ScanError.ocrUnavailable, e);
    }
  }

  @override
  Future<void> dispose() async {
    final recognizer = _recognizer;
    _recognizer = null;
    try {
      await recognizer?.close();
    } on Object {
      // Nothing to release if the native side was never created.
    }
  }
}
