import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Offset, Rect, Size;

import '../../../core/error/app_exception.dart';
import 'scan_image_source.dart';

/// Cuts a region out of a page image so it can be recognized on its own.
/// Abstracted so tests can use a fake.
abstract interface class ImageCropper {
  /// A temporary PNG of [region] (pixels of the upright image) of [image],
  /// enlarged when small so print stays legible for OCR. The caller
  /// discards it. Throws [ScanException].
  Future<PickedImage> crop(PickedImage image, Rect region);
}

/// Pixel size of the upright (orientation-corrected) image at [path], as
/// the app displays it and as OCR word boxes refer to it.
Future<Size> readImageSize(String path) async {
  final image = await _decode(path);
  try {
    return Size(image.width.toDouble(), image.height.toDouble());
  } finally {
    image.dispose();
  }
}

Future<ui.Image> _decode(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

/// Crops on the device with `dart:ui`; nothing leaves the phone.
class DartUiImageCropper implements ImageCropper {
  const DartUiImageCropper();

  /// Crops whose longer side is below this are enlarged up to 2×.
  static const _minLongSide = 1200.0;

  @override
  Future<PickedImage> crop(PickedImage image, Rect region) async {
    final ui.Image source;
    try {
      source = await _decode(image.path);
    } on Object catch (e) {
      throw ScanException(ScanError.unreadableImage, e);
    }
    try {
      final bounds =
          Offset.zero & Size(source.width.toDouble(), source.height.toDouble());
      final area = region.intersect(bounds);
      if (area.width < 1 || area.height < 1) {
        throw const ScanException(ScanError.unreadableImage);
      }
      final longSide = area.width > area.height ? area.width : area.height;
      final factor = longSide >= _minLongSide
          ? 1.0
          : (_minLongSide / longSide).clamp(1.0, 2.0);
      final width = (area.width * factor).round();
      final height = (area.height * factor).round();

      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        source,
        area,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(width, height);
      picture.dispose();
      final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      if (png == null) throw const ScanException(ScanError.unreadableImage);

      final file = File(
        '${Directory.systemTemp.path}/wortbox_region_'
        '${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
      return PickedImage(
        path: file.path,
        name: 'region.png',
        sizeBytes: await file.length(),
      );
    } on ScanException {
      rethrow;
    } on Object catch (e) {
      throw ScanException(ScanError.unreadableImage, e);
    } finally {
      source.dispose();
    }
  }
}
