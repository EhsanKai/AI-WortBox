import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';

enum ImageOrigin { camera, gallery }

/// A page image picked by the user. [path] points to a temporary copy owned
/// by the app, which is deleted after recognition.
@immutable
class PickedImage {
  const PickedImage({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int sizeBytes;
}

/// Obtains page images. Abstracted so tests can use a fake.
abstract interface class ScanImageSource {
  /// The picked image, or null when the user cancelled.
  /// Throws [ScanException] for permission and availability problems.
  Future<PickedImage?> pick(ImageOrigin origin);

  /// An image picked before Android destroyed the activity (low memory while
  /// the camera was open), or null.
  Future<PickedImage?> retrieveLost();

  /// Deletes the temporary copy of [image]. Never throws.
  Future<void> discard(PickedImage image);
}

/// Image formats the on-device recognizer can read on both platforms.
const supportedImageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'heif',
  'bmp',
};

/// Throws [ScanException] if the image cannot be used for OCR.
void validatePickedImage(PickedImage image) {
  final dot = image.name.lastIndexOf('.');
  final extension = dot < 0 ? '' : image.name.substring(dot + 1).toLowerCase();
  if (!supportedImageExtensions.contains(extension)) {
    throw const ScanException(ScanError.unsupportedFormat);
  }
  if (image.sizeBytes <= 0) {
    throw const ScanException(ScanError.unreadableImage);
  }
  if (image.sizeBytes > AppConfig.maxScanImageBytes) {
    throw const ScanException(ScanError.imageTooLarge);
  }
}

class ImagePickerScanImageSource implements ScanImageSource {
  ImagePickerScanImageSource([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick(ImageOrigin origin) async {
    try {
      final file = await _picker.pickImage(
        source: origin == ImageOrigin.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        // Downscale very large photos; text stays legible for OCR.
        maxWidth: AppConfig.maxScanImageDimension,
        maxHeight: AppConfig.maxScanImageDimension,
        imageQuality: 92,
        // No location or other metadata is needed.
        requestFullMetadata: false,
      );
      return file == null ? null : await _toPicked(file);
    } on PlatformException catch (e) {
      throw ScanException(mapPickerErrorCode(e.code, origin), e);
    }
  }

  @override
  Future<PickedImage?> retrieveLost() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await _picker.retrieveLostData();
      final file = response.file;
      if (response.isEmpty || file == null) return null;
      return await _toPicked(file);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> discard(PickedImage image) async {
    try {
      final file = File(image.path);
      if (await file.exists()) await file.delete();
    } on Object {
      // Temporary files are also cleaned up by the operating system.
    }
  }

  Future<PickedImage> _toPicked(XFile file) async {
    try {
      return PickedImage(
        path: file.path,
        name: file.name,
        sizeBytes: await file.length(),
      );
    } on Object catch (e) {
      throw ScanException(ScanError.unreadableImage, e);
    }
  }
}

/// Maps `image_picker` platform error codes to [ScanError]s.
@visibleForTesting
ScanError mapPickerErrorCode(String code, ImageOrigin origin) => switch (code) {
  'camera_access_denied' => ScanError.cameraPermissionDenied,
  'photo_access_denied' ||
  'photo_access_restricted' => ScanError.photoPermissionDenied,
  'no_available_camera' => ScanError.cameraUnavailable,
  'invalid_image' || 'invalid_source' => ScanError.unsupportedFormat,
  _ =>
    origin == ImageOrigin.camera
        ? ScanError.cameraUnavailable
        : ScanError.unreadableImage,
};
