import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/scan/data/scan_image_source.dart';
import 'package:flutter_test/flutter_test.dart';

PickedImage image(String name, int size) =>
    PickedImage(path: '/tmp/$name', name: name, sizeBytes: size);

Matcher throwsScan(ScanError error) =>
    throwsA(isA<ScanException>().having((e) => e.error, 'error', error));

void main() {
  test('accepts common photo formats in any case', () {
    for (final name in ['a.jpg', 'b.JPEG', 'c.png', 'd.heic', 'e.webp']) {
      expect(() => validatePickedImage(image(name, 1000)), returnsNormally);
    }
  });

  test('rejects unsupported, empty and oversized images', () {
    expect(
      () => validatePickedImage(image('page.pdf', 1000)),
      throwsScan(ScanError.unsupportedFormat),
    );
    expect(
      () => validatePickedImage(image('noextension', 1000)),
      throwsScan(ScanError.unsupportedFormat),
    );
    expect(
      () => validatePickedImage(image('a.jpg', 0)),
      throwsScan(ScanError.unreadableImage),
    );
    expect(
      () =>
          validatePickedImage(image('a.jpg', AppConfig.maxScanImageBytes + 1)),
      throwsScan(ScanError.imageTooLarge),
    );
  });

  test('maps image_picker error codes', () {
    expect(
      mapPickerErrorCode('camera_access_denied', ImageOrigin.camera),
      ScanError.cameraPermissionDenied,
    );
    expect(
      mapPickerErrorCode('photo_access_denied', ImageOrigin.gallery),
      ScanError.photoPermissionDenied,
    );
    expect(
      mapPickerErrorCode('photo_access_restricted', ImageOrigin.gallery),
      ScanError.photoPermissionDenied,
    );
    expect(
      mapPickerErrorCode('no_available_camera', ImageOrigin.camera),
      ScanError.cameraUnavailable,
    );
    expect(
      mapPickerErrorCode('invalid_image', ImageOrigin.gallery),
      ScanError.unsupportedFormat,
    );
    expect(
      mapPickerErrorCode('something_else', ImageOrigin.gallery),
      ScanError.unreadableImage,
    );
  });
}
