import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/text/text_normalizer.dart';

// Every choice is stored by its enum name. Unknown names (e.g. from a newer
// app) read as the default, so a stored appearance can never break a card.

/// Background tint of a card. Each has a light and a dark-mode colour with
/// tested contrast for every [CardInk].
enum CardColor { standard, sun, mint, sky, rose, lavender, sand }

/// Colour of the card's main text (the German word and the meanings).
enum CardInk { standard, navy, green, plum, brown }

/// Marker colour for highlighted parts.
enum HighlightColor { yellow, green, pink, blue }

/// Built-in stickers (emoji: no assets, no network).
enum CardSticker {
  star('⭐'),
  fire('🔥'),
  bulb('💡'),
  heart('❤️'),
  check('✅'),
  warning('⚠️'),
  target('🎯'),
  pin('📌'),
  brain('🧠'),
  sprout('🌱'),
  books('📚'),
  germany('🇩🇪');

  const CardSticker(this.emoji);

  final String emoji;
}

/// Which part of the card a highlight belongs to.
enum HighlightField { word, meaning }

/// A highlighted piece of text: one word of the German word, or one whole
/// meaning. Stored as the text itself (not as character offsets), so editing
/// the word can only make a highlight disappear, never shift it onto other
/// text or change the word.
@immutable
class CardHighlight {
  const CardHighlight(this.field, this.text);

  final HighlightField field;
  final String text;

  /// Comparison key: case-, whitespace- and (for Persian) letter-variant
  /// insensitive.
  String get key => field == HighlightField.word
      ? TextNormalizer.vocabularyKey(text)
      : TextNormalizer.meaningKey(text);

  Map<String, String> toJson() => {'f': field.name, 't': text};

  static CardHighlight? fromJson(Object? json) {
    if (json is! Map) return null;
    final field = HighlightField.values
        .where((f) => f.name == json['f'])
        .firstOrNull;
    final text = json['t'];
    if (field == null || text is! String || text.trim().isEmpty) return null;
    return CardHighlight(field, text);
  }

  @override
  bool operator ==(Object other) =>
      other is CardHighlight && other.field == field && other.key == key;

  @override
  int get hashCode => Object.hash(field, key);
}

/// How one word's card looks. Card-specific: it never affects other cards,
/// and it is presentation only (no vocabulary content, no review state).
@immutable
class CardAppearance {
  const CardAppearance({
    this.background = CardColor.standard,
    this.ink = CardInk.standard,
    this.wordScale = 1,
    this.meaningScale = 1,
    this.highlightColor = HighlightColor.yellow,
    this.highlights = const {},
    this.sticker,
  });

  static const standard = CardAppearance();

  /// Allowed text sizes, relative to the normal size.
  static const scales = [0.85, 1.0, 1.2, 1.4, 1.6];
  static const minScale = 0.85;
  static const maxScale = 1.6;

  final CardColor background;
  final CardInk ink;

  /// Size of the German word, relative to the normal size.
  final double wordScale;

  /// Size of the Persian meanings, relative to the normal size.
  final double meaningScale;
  final HighlightColor highlightColor;
  final Set<CardHighlight> highlights;
  final CardSticker? sticker;

  bool get isStandard => this == standard;

  /// Clamps a stored or chosen size to the allowed range.
  static double clampScale(double value) =>
      value.isFinite ? value.clamp(minScale, maxScale).toDouble() : 1;

  bool isHighlighted(HighlightField field, String text) =>
      highlights.contains(CardHighlight(field, text));

  CardAppearance copyWith({
    CardColor? background,
    CardInk? ink,
    double? wordScale,
    double? meaningScale,
    HighlightColor? highlightColor,
    Set<CardHighlight>? highlights,
    CardSticker? Function()? sticker,
  }) => CardAppearance(
    background: background ?? this.background,
    ink: ink ?? this.ink,
    wordScale: clampScale(wordScale ?? this.wordScale),
    meaningScale: clampScale(meaningScale ?? this.meaningScale),
    highlightColor: highlightColor ?? this.highlightColor,
    highlights: highlights ?? this.highlights,
    sticker: sticker != null ? sticker() : this.sticker,
  );

  /// Adds or removes the highlight of [text].
  CardAppearance toggleHighlight(HighlightField field, String text) {
    final h = CardHighlight(field, text);
    final next = {...highlights};
    if (!next.remove(h)) next.add(h);
    return copyWith(highlights: next);
  }

  /// The stored form of [highlights] (JSON).
  String get highlightsJson =>
      jsonEncode([for (final h in highlights) h.toJson()]);

  /// Reads stored highlights; anything unreadable is ignored.
  static Set<CardHighlight> parseHighlights(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      final list = jsonDecode(json);
      if (list is! List) return const {};
      return {for (final item in list) ?CardHighlight.fromJson(item)};
    } on FormatException {
      return const {};
    }
  }

  static T byName<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  @override
  bool operator ==(Object other) =>
      other is CardAppearance &&
      other.background == background &&
      other.ink == ink &&
      other.wordScale == wordScale &&
      other.meaningScale == meaningScale &&
      other.highlightColor == highlightColor &&
      setEquals(other.highlights, highlights) &&
      other.sticker == sticker;

  @override
  int get hashCode => Object.hash(
    background,
    ink,
    wordScale,
    meaningScale,
    highlightColor,
    Object.hashAllUnordered(highlights),
    sticker,
  );
}

/// Persistence of card appearances. Writes only `card_appearances`: never
/// vocabulary content (`updatedAt` is unchanged), `flashcards` or
/// `review_events`.
abstract interface class CardAppearanceRepository {
  /// The appearance of entry [entryId]'s card; the standard one when none
  /// is saved.
  Stream<CardAppearance> watch(String entryId);

  Future<CardAppearance> get(String entryId);

  /// Saves [appearance] for [entryId]. The standard appearance removes the
  /// stored row.
  Future<void> save(String entryId, CardAppearance appearance);
}
