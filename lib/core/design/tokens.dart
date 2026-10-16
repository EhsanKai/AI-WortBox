import 'package:flutter/widgets.dart';

/// Spacing scale (logical pixels). Layouts use only these values.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page gutter.
  static const double gutter = lg;

  /// Bottom padding for lists under an extended floating action button.
  static const double fabClearance = 96;
}

/// Corner radii.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Border widths. Surfaces are separated by hairlines, not shadows.
abstract final class AppBorder {
  static const double hairline = 1;
  static const double focus = 2;
  static const double emphasis = 1.5;
}

/// Elevation. The design is flat; only floating elements are raised.
abstract final class AppElevation {
  static const double flat = 0;
  static const double floating = 2;
  static const double overlay = 3;
}

/// Icon sizes.
abstract final class AppIconSize {
  static const double sm = 18;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
}

/// Interaction sizes.
abstract final class AppTouch {
  /// Minimum touch target (Android and Apple accessibility guidance).
  static const double minTarget = 48;

  /// Height of primary and secondary buttons.
  static const double buttonHeight = 52;
}

/// Animation durations.
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
}
