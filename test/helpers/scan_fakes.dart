import 'dart:ui' show Rect, Size;

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/scan/data/image_cropper.dart';
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

/// Size of the photo [fakePageLayout] lays text out on.
const fakePageSize = Size(1200, 1400);

/// Lays [text] out like a printed page: one block per paragraph (split on
/// blank lines), one line per `\n`, words split on spaces, each character
/// [charWidth] pixels wide and each line 40 pixels high.
List<List<OcrLine>> fakePageLayout(String text, {double charWidth = 22}) {
  var y = 80.0;
  final blocks = <List<OcrLine>>[];
  for (final paragraph in text.split('\n\n')) {
    final lines = <OcrLine>[];
    for (final line in paragraph.split('\n')) {
      final elements = <OcrElement>[];
      var x = 40.0;
      for (final word in line.split(' ')) {
        if (word.isNotEmpty) {
          elements.add(
            OcrElement(
              word,
              Rect.fromLTWH(x, y, word.length * charWidth, 40),
              confidence: 0.9,
            ),
          );
        }
        x += (word.length + 1) * charWidth;
      }
      lines.add(
        OcrLine(
          line,
          box: Rect.fromLTWH(40, y, line.length * charWidth, 40),
          elements: elements,
        ),
      );
      y += 70;
    }
    blocks.add(lines);
    y += 60;
  }
  return blocks;
}

/// The box of the [occurrence]th element reading [word] in
/// [fakePageLayout] of [text].
Rect fakeBoxOf(String text, String word, {int occurrence = 0}) => [
  for (final block in fakePageLayout(text))
    for (final line in block)
      for (final e in line.elements)
        if (e.text == word) e.box,
][occurrence];

/// Returns OCR [lines] as one block per paragraph (split on blank lines).
///
/// With [layout], words come with boxes on a [fakePageSize] photo (see
/// [fakePageLayout]). A crop made by [FakeImageCropper] is recognized as
/// [regionText].
class FakeTextRecognitionEngine implements TextRecognitionEngine {
  FakeTextRecognitionEngine(
    this.text, {
    this.error,
    this.isAvailable = true,
    this.layout = false,
    this.regionText = '',
  });

  String text;
  ScanException? error;
  @override
  bool isAvailable;
  bool layout;
  String regionText;
  int calls = 0;
  bool disposed = false;

  @override
  Future<ScanText> recognize(PickedImage image) async {
    calls++;
    if (error != null) throw error!;
    if (image.name == fakeRegion.name) {
      return ScanText.fromOcrLayout(
        fakePageLayout(regionText),
        rawText: regionText,
        imageSize: fakePageSize,
      );
    }
    if (layout) {
      return ScanText.fromOcrLayout(
        fakePageLayout(text),
        rawText: text,
        imageSize: fakePageSize,
      );
    }
    final blocks = [
      for (final paragraph in text.split('\n\n'))
        [for (final line in paragraph.split('\n')) (line, null)],
    ];
    return ScanText.fromRecognizedBlocks(blocks, rawText: text);
  }

  @override
  Future<void> dispose() async => disposed = true;
}

const fakeRegion = PickedImage(
  path: '/tmp/fake/region.png',
  name: 'region.png',
  sizeBytes: 512,
);

/// Records requested crops and returns [fakeRegion] (or throws [error]).
class FakeImageCropper implements ImageCropper {
  final crops = <(PickedImage, Rect)>[];
  ScanException? error;

  @override
  Future<PickedImage> crop(PickedImage image, Rect region) async {
    if (error != null) throw error!;
    crops.add((image, region));
    return fakeRegion;
  }
}
