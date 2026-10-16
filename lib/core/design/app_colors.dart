import 'package:flutter/material.dart';

/// Raw brand colors. Widgets use [ColorScheme] roles or [AppColors] tokens,
/// never these values directly.
///
/// All text/background pairs used by the themes meet WCAG AA (4.5:1) and
/// input outlines meet 3:1; see test/core/design/contrast_test.dart.
abstract final class AppPalette {
  // Warm yellow: the vocabulary box.
  static const boxYellow = Color(0xFFF2B630);
  static const boxYellowBright = Color(0xFFF4C04A);
  static const highlighter = Color(0xFFFCE39A);
  static const yellowTint = Color(0xFFFDF0C9);
  static const yellowInk = Color(0xFF7A5300);
  static const yellowDeep = Color(0xFF463711);
  static const yellowPale = Color(0xFFFCE7AE);

  // Deep navy: structure and type.
  static const navy950 = Color(0xFF0D1424);
  static const navy900 = Color(0xFF15213B);
  static const navy800 = Color(0xFF1B2B4B);
  static const navy700 = Color(0xFF253659);
  static const navy600 = Color(0xFF2B3856);
  static const navy100 = Color(0xFFDCE3F0);
  static const navy50 = Color(0xFFE3E9F6);
  static const slate = Color(0xFF4F5870);
  static const slateLight = Color(0xFFB3BACB);
  static const slateOutline = Color(0xFF7D89A6);

  // Mint: restrained AI / assistance accent.
  static const mintInk = Color(0xFF0F6B55);
  static const mintTint = Color(0xFFD5F0E7);
  static const mintDeep = Color(0xFF0A4A3B);
  static const mintBright = Color(0xFF63D6B6);
  static const mintNight = Color(0xFF123D34);
  static const mintPale = Color(0xFFBFEFE0);

  // Warm cream surfaces.
  static const cream = Color(0xFFFBF7EE);
  static const paper = Color(0xFFFFFDF8);
  static const creamDeep = Color(0xFFF4EEE1);
  static const creamLine = Color(0xFFE3D9C4);
  static const creamOutline = Color(0xFF857C69);

  // Errors.
  static const red = Color(0xFFB42318);
  static const redTint = Color(0xFFFBE3DF);
  static const redDeep = Color(0xFF6E1410);
  static const redSoft = Color(0xFFFFB4A9);
  static const redNight = Color(0xFF5C1A14);
  static const redPale = Color(0xFFFFDAD4);
}

/// Tone of a status, banner or badge.
enum StatusTone { neutral, success, warning, danger, accent }

/// A foreground/background pair for one [StatusTone].
@immutable
class ToneColors {
  const ToneColors({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

/// Semantic colors that [ColorScheme] has no role for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.box,
    required this.onBox,
    required this.highlight,
    required this.onHighlight,
    required this.inputFill,
    required this.paper,
    required this.success,
    required this.warning,
    required this.danger,
    required this.accent,
    required this.neutral,
  });

  /// The vocabulary-box yellow (brand mark, floating actions, nav indicator).
  final Color box;
  final Color onBox;

  /// A selected word on a scanned page, like a highlighter stroke.
  final Color highlight;
  final Color onHighlight;

  /// Fill of text fields.
  final Color inputFill;

  /// Background of the scanned-page reading surface.
  final Color paper;

  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;
  final ToneColors accent;
  final ToneColors neutral;

  ToneColors tone(StatusTone tone) => switch (tone) {
    StatusTone.neutral => neutral,
    StatusTone.success => success,
    StatusTone.warning => warning,
    StatusTone.danger => danger,
    StatusTone.accent => accent,
  };

  static const light = AppColors(
    box: AppPalette.boxYellow,
    onBox: AppPalette.navy900,
    highlight: AppPalette.highlighter,
    onHighlight: AppPalette.navy900,
    inputFill: AppPalette.paper,
    paper: AppPalette.paper,
    success: ToneColors(
      foreground: AppPalette.mintDeep,
      background: AppPalette.mintTint,
    ),
    warning: ToneColors(
      foreground: AppPalette.yellowInk,
      background: AppPalette.yellowTint,
    ),
    danger: ToneColors(
      foreground: AppPalette.redDeep,
      background: AppPalette.redTint,
    ),
    accent: ToneColors(
      foreground: AppPalette.mintDeep,
      background: AppPalette.mintTint,
    ),
    neutral: ToneColors(
      foreground: AppPalette.slate,
      background: AppPalette.creamDeep,
    ),
  );

  static const dark = AppColors(
    box: AppPalette.boxYellowBright,
    onBox: AppPalette.navy900,
    highlight: AppPalette.boxYellowBright,
    onHighlight: AppPalette.navy900,
    inputFill: Color(0xFF1A2439),
    paper: Color(0xFF172036),
    success: ToneColors(
      foreground: AppPalette.mintPale,
      background: AppPalette.mintNight,
    ),
    warning: ToneColors(
      foreground: AppPalette.yellowPale,
      background: AppPalette.yellowDeep,
    ),
    danger: ToneColors(
      foreground: AppPalette.redPale,
      background: AppPalette.redNight,
    ),
    accent: ToneColors(
      foreground: AppPalette.mintPale,
      background: AppPalette.mintNight,
    ),
    neutral: ToneColors(
      foreground: AppPalette.slateLight,
      background: Color(0xFF212D49),
    ),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
