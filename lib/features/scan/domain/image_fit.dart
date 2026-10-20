import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show Matrix4, MatrixUtils;

/// How an image of [imageSize] pixels is shown centred and scaled to fit
/// (like `BoxFit.contain`) in a [viewport] of logical pixels, and the
/// mapping between the two coordinate systems.
///
/// Zoom and pan are applied on top by a transform (an `InteractiveViewer`);
/// convert a screen point to the untransformed viewport first (its
/// `toScene`), then with [toImage].
@immutable
class ImageFit {
  const ImageFit._(this.imageSize, this.viewport, this.scale, this.offset);

  factory ImageFit.contain(Size imageSize, Size viewport) {
    if (imageSize.isEmpty || viewport.isEmpty) {
      return ImageFit._(imageSize, viewport, 1, Offset.zero);
    }
    final scale =
        viewport.width / imageSize.width < viewport.height / imageSize.height
        ? viewport.width / imageSize.width
        : viewport.height / imageSize.height;
    final offset = Offset(
      (viewport.width - imageSize.width * scale) / 2,
      (viewport.height - imageSize.height * scale) / 2,
    );
    return ImageFit._(imageSize, viewport, scale, offset);
  }

  final Size imageSize;
  final Size viewport;

  /// Logical pixels per image pixel.
  final double scale;

  /// Top-left corner of the image in the viewport.
  final Offset offset;

  /// Where the image is drawn in the viewport.
  Rect get imageRect => offset & (imageSize * scale);

  Offset toView(Offset imagePoint) => offset + imagePoint * scale;

  Rect toViewRect(Rect imageRect) =>
      Rect.fromPoints(toView(imageRect.topLeft), toView(imageRect.bottomRight));

  Offset toImage(Offset viewPoint) => (viewPoint - offset) / scale;

  /// [viewportPoint] (on screen, relative to the viewer) in image pixels:
  /// the viewer's zoom/pan [transform] is undone first, then the fit. Not
  /// clipped: points in the letterbox lie outside the image.
  Offset toImageThrough(Matrix4 transform, Offset viewportPoint) => toImage(
    MatrixUtils.transformPoint(Matrix4.inverted(transform), viewportPoint),
  );

  @override
  bool operator ==(Object other) =>
      other is ImageFit &&
      other.imageSize == imageSize &&
      other.viewport == viewport;

  @override
  int get hashCode => Object.hash(imageSize, viewport);

  /// [viewRect] in image pixels, clipped to the image.
  Rect toImageRect(Rect viewRect) => Rect.fromPoints(
    toImage(viewRect.topLeft),
    toImage(viewRect.bottomRight),
  ).intersect(Offset.zero & imageSize);
}
