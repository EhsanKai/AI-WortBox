import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/scan/data/scan_image_source.dart';
import 'package:ai_wortbox/features/scan/data/text_recognition_engine.dart';
import 'package:ai_wortbox/features/scan/domain/scan_text.dart';

const fakePhoto = PickedImage(
  path: '/tmp/fake/page.jpg',
  name: 'page.jpg',
  sizeBytes: 1024,
);

/// Returns [image] (or throws [error]) and records discarded images.
class FakeScanImageSource implements ScanImageSource {
  FakeScanImageSource({this.image = fakePhoto, this.error, this.lost});

  PickedImage? image;
  ScanException? error;
  PickedImage? lost;
  final List<ImageOrigin> requested = [];
  final List<PickedImage> discarded = [];

  @override
  Future<PickedImage?> pick(ImageOrigin origin) async {
    requested.add(origin);
    if (error != null) throw error!;
    return image;
  }

  @override
  Future<PickedImage?> retrieveLost() async {
    final result = lost;
    lost = null;
    return result;
  }

  @override
  Future<void> discard(PickedImage image) async => discarded.add(image);
}

/// Returns OCR [lines] as one block per paragraph (split on blank lines).
class FakeTextRecognitionEngine implements TextRecognitionEngine {
  FakeTextRecognitionEngine(this.text, {this.error, this.isAvailable = true});

  String text;
  ScanException? error;
  @override
  bool isAvailable;
  int calls = 0;
  bool disposed = false;

  @override
  Future<ScanText> recognize(PickedImage image) async {
    calls++;
    if (error != null) throw error!;
    final blocks = [
      for (final paragraph in text.split('\n\n'))
        [for (final line in paragraph.split('\n')) (line, null)],
    ];
    return ScanText.fromRecognizedBlocks(blocks, rawText: text);
  }

  @override
  Future<void> dispose() async => disposed = true;
}
