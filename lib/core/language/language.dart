import 'package:flutter/foundation.dart';

/// A language identified by its ISO 639-1 / BCP-47 code.
///
/// Languages are persisted by [code] only, so new languages can be added to
/// [Language.supported] later without changing the database schema or the
/// vocabulary domain model.
@immutable
class Language {
  const Language._({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.isRightToLeft,
  });

  /// A language that is stored in the database but unknown to this build
  /// (e.g. data created by a newer app version). It is kept as-is.
  const Language.unknown(this.code)
    : englishName = code,
      nativeName = code,
      isRightToLeft = false;

  final String code;
  final String englishName;
  final String nativeName;
  final bool isRightToLeft;

  static const german = Language._(
    code: 'de',
    englishName: 'German',
    nativeName: 'Deutsch',
    isRightToLeft: false,
  );

  static const persian = Language._(
    code: 'fa',
    englishName: 'Persian',
    nativeName: 'فارسی',
    isRightToLeft: true,
  );

  /// Languages this build fully supports.
  static const List<Language> supported = [german, persian];

  bool get isSupported => supported.contains(this);

  /// Resolves a stored language [code]. Unknown codes are preserved via
  /// [Language.unknown] instead of throwing, so old builds never crash on
  /// data written by newer ones.
  static Language fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final language in supported) {
      if (language.code == normalized) return language;
    }
    return Language.unknown(normalized);
  }

  @override
  bool operator ==(Object other) => other is Language && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Language($code)';
}
