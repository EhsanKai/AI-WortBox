import 'package:flutter/material.dart';

/// Font families bundled in assets/fonts (SIL Open Font License 1.1).
abstract final class AppFonts {
  /// Persian UI text. Also covers Latin, so mixed UI strings stay consistent.
  static const ui = 'Vazirmatn';

  /// German vocabulary, examples and scanned text. A book face that matches
  /// the "from the page" idea and keeps umlauts, ß and „quotes“ distinct.
  static const german = 'Literata';

  static const uiFallback = [german];
  static const germanFallback = [ui];
}

/// Text hierarchy.
///
/// Persian UI styles use generous line heights (Arabic script needs room for
/// dots and diacritics). German styles are separate so that the headword is
/// always the most prominent element, while Persian meanings stay readable.
abstract final class AppTypography {
  static TextStyle _ui(double size, double height, FontWeight weight) =>
      TextStyle(
        fontFamily: AppFonts.ui,
        fontFamilyFallback: AppFonts.uiFallback,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: 0,
      );

  static TextStyle _german(double size, double height, FontWeight weight) =>
      TextStyle(
        fontFamily: AppFonts.german,
        fontFamilyFallback: AppFonts.germanFallback,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: 0,
      );

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
    displaySmall: _ui(32, 1.25, FontWeight.w700).copyWith(color: ink),
    headlineMedium: _ui(26, 1.35, FontWeight.w700).copyWith(color: ink),
    headlineSmall: _ui(22, 1.4, FontWeight.w700).copyWith(color: ink),
    titleLarge: _ui(19, 1.45, FontWeight.w700).copyWith(color: ink),
    titleMedium: _ui(16, 1.5, FontWeight.w500).copyWith(color: ink),
    titleSmall: _ui(14, 1.5, FontWeight.w700).copyWith(color: ink),
    bodyLarge: _ui(16, 1.7, FontWeight.w400).copyWith(color: ink),
    bodyMedium: _ui(14.5, 1.65, FontWeight.w400).copyWith(color: ink),
    bodySmall: _ui(13, 1.6, FontWeight.w400).copyWith(color: muted),
    labelLarge: _ui(15, 1.4, FontWeight.w500).copyWith(color: ink),
    labelMedium: _ui(13, 1.4, FontWeight.w500).copyWith(color: ink),
    labelSmall: _ui(12, 1.4, FontWeight.w500).copyWith(color: muted),
  );

  /// The German word on its detail screen.
  static final headword = _german(30, 1.25, FontWeight.w600);

  /// The German word in lists, cards and dialogs.
  static final wordTitle = _german(19, 1.3, FontWeight.w600);

  /// German example sentences, source context and form input.
  static final germanBody = _german(17, 1.55, FontWeight.w400);

  /// Words on the scanned-page reading surface.
  static final pageText = _german(19, 1.4, FontWeight.w400);
}
