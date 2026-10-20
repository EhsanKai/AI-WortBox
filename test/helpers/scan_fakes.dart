import 'dart:ui' show Offset, Rect, Size;

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

/// Recognizes [text] like a page: one block per paragraph (split on blank
/// lines), one line per `\n`.
///
/// With [layout], words come with boxes on a [fakePageSize] photo (see
/// [fakePageLayout]).
///
/// A crop made by [FakeImageCropper] is "read" like the real engine would:
/// only the words of the page whose boxes lie inside the crop, with boxes in
/// crop pixels. [regionText] replaces that result (as text without word
/// positions); [regionError] makes reading a crop fail.
class FakeTextRecognitionEngine implements TextRecognitionEngine {
  FakeTextRecognitionEngine(
    this.text, {
    this.error,
    this.isAvailable = true,
    this.layout = false,
    this.regionText,
    this.regionError,
  });

  String text;
  ScanException? error;
  @override
  bool isAvailable;
  bool layout;
  String? regionText;
  ScanException? regionError;
  int calls = 0;
  bool disposed = false;

  /// Every image recognized, in order.
  final recognized = <PickedImage>[];

  /// Crops recognized, as photo regions.
  Iterable<Rect> get readRegions =>
      recognized.map((i) => FakeImageCropper.regionOf(i)).whereType<Rect>();

  /// Whether the whole page photo was ever recognized.
  bool get readWholePage => recognized.any((i) => i.path == fakePhoto.path);

  @override
  Future<ScanText> recognize(PickedImage image) async {
    calls++;
    recognized.add(image);
    final region = FakeImageCropper.regionOf(image);
    if (region != null) {
      if (regionError != null) throw regionError!;
      if (regionText case final t?) {
        return ScanText.fromRecognizedBlocks([
          for (final line in t.split('\n')) [(line, null)],
        ], rawText: t);
      }
      return _readCrop(region, FakeImageCropper.scaleOf(image));
    }
    if (error != null) throw error!;
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

  ScanText _readCrop(Rect region, double scale) {
    Rect toCrop(Rect r) => Rect.fromLTRB(
      (r.left - region.left) * scale,
      (r.top - region.top) * scale,
      (r.right - region.left) * scale,
      (r.bottom - region.top) * scale,
    );
    final blocks = <List<OcrLine>>[];
    for (final block in fakePageLayout(text)) {
      final lines = <OcrLine>[];
      for (final line in block) {
        final inside = [
          for (final e in line.elements)
            if (region.contains(e.box.center))
              OcrElement(e.text, toCrop(e.box), confidence: e.confidence),
        ];
        if (inside.isEmpty) continue;
        lines.add(
          OcrLine(inside.map((e) => e.text).join(' '), elements: inside),
        );
      }
      if (lines.isNotEmpty) blocks.add(lines);
    }
    return ScanText.fromOcrLayout(
      blocks,
      rawText: blocks.expand((b) => b).map((l) => l.text).join('\n'),
      imageSize: region.size * scale,
    );
  }

  @override
  Future<void> dispose() async => disposed = true;
}

/// Cuts nothing: returns a fake crop that remembers its region (read back
/// by [FakeTextRecognitionEngine]). Records every requested region.
class FakeImageCropper implements ImageCropper {
  FakeImageCropper({this.size = fakePageSize, this.scale = 2});

  Size size;
  double scale;
  ScanException? sizeError;
  ScanException? error;
  final crops = <(PickedImage, Rect)>[];

  static const _prefix = 'fake-region:';

  static Rect? regionOf(PickedImage image) {
    if (!image.path.startsWith(_prefix)) return null;
    final v = image.path.substring(_prefix.length).split(',');
    return Rect.fromLTRB(
      double.parse(v[0]),
      double.parse(v[1]),
      double.parse(v[2]),
      double.parse(v[3]),
    );
  }

  static double scaleOf(PickedImage image) =>
      double.parse(image.name.split('@').last);

  @override
  Future<Size> imageSize(PickedImage image) async {
    if (sizeError != null) throw sizeError!;
    return size;
  }

  @override
  Future<CroppedImage> crop(PickedImage image, Rect region) async {
    if (error != null) throw error!;
    crops.add((image, region));
    final area = region.intersect(Offset.zero & size);
    return CroppedImage(
      image: PickedImage(
        path: '$_prefix${area.left},${area.top},${area.right},${area.bottom}',
        name: 'region@$scale',
        sizeBytes: 512,
      ),
      region: area,
      scale: scale,
    );
  }
}
