import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../domain/card_appearance.dart';

/// The appearance of a word's card, updated when it is saved.
final cardAppearanceProvider = StreamProvider.family<CardAppearance, String>(
  (ref, entryId) => ref.watch(cardAppearanceRepositoryProvider).watch(entryId),
);

/// Colours of the card choices in light and dark mode. Every ink has at
/// least 4.5:1 contrast on every background, on the standard card and page
/// surfaces, and on every highlight (test/core/design/contrast_test.dart).
abstract final class CardPalette {
  static Color? background(CardColor c, Brightness b) {
    final dark = b == Brightness.dark;
    return switch (c) {
      CardColor.standard => null,
      CardColor.sun => dark ? const Color(0xFF4A3B12) : const Color(0xFFFFF3C4),
      CardColor.mint =>
        dark ? const Color(0xFF163D33) : const Color(0xFFDDF3EA),
      CardColor.sky => dark ? const Color(0xFF172F4A) : const Color(0xFFDCEBFB),
      CardColor.rose =>
        dark ? const Color(0xFF47202A) : const Color(0xFFFBE1E6),
      CardColor.lavender =>
        dark ? const Color(0xFF2E2647) : const Color(0xFFE9E2F8),
      CardColor.sand =>
        dark ? const Color(0xFF3B3226) : const Color(0xFFF3E9D7),
    };
  }

  static Color? ink(CardInk c, Brightness b) {
    final dark = b == Brightness.dark;
    return switch (c) {
      CardInk.standard => null,
      CardInk.navy => dark ? const Color(0xFFDCE3F0) : const Color(0xFF1B2B4B),
      CardInk.green => dark ? const Color(0xFFBFEFE0) : const Color(0xFF0A4A3B),
      CardInk.plum => dark ? const Color(0xFFF1D7F5) : const Color(0xFF5B2266),
      CardInk.brown => dark ? const Color(0xFFF4E1C1) : const Color(0xFF5A3A12),
    };
  }

  static Color highlight(HighlightColor c, Brightness b) {
    final dark = b == Brightness.dark;
    return switch (c) {
      HighlightColor.yellow =>
        dark ? const Color(0xFF6B5414) : const Color(0xFFFCE39A),
      HighlightColor.green =>
        dark ? const Color(0xFF1F5C4C) : const Color(0xFFBFEFE0),
      HighlightColor.pink =>
        dark ? const Color(0xFF6B2A3B) : const Color(0xFFF8C8D4),
      HighlightColor.blue =>
        dark ? const Color(0xFF234A75) : const Color(0xFFC9DEF7),
    };
  }

  /// The ink for text on a card: the chosen one, or the theme's text colour.
  static Color inkOf(BuildContext context, CardAppearance a) {
    final theme = Theme.of(context);
    return ink(a.ink, theme.brightness) ?? theme.colorScheme.onSurface;
  }
}

/// A card with the appearance's background and sticker. The sticker sits
/// in its own corner area above the content, so it never covers text.
class AppearanceCardFrame extends StatelessWidget {
  const AppearanceCardFrame({
    super.key,
    required this.appearance,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xl),
  });

  final CardAppearance appearance;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final sticker = appearance.sticker;
    return Card(
      color: CardPalette.background(
        appearance.background,
        Theme.of(context).brightness,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sticker != null)
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Semantics(
                  label: sticker.name,
                  child: Text(
                    sticker.emoji,
                    key: const Key('card.sticker'),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// [text] with the appearance's highlights. For the German word each
/// whitespace-separated word can be highlighted; a meaning is highlighted
/// as a whole. The text itself (line breaks, umlauts, Persian letters and
/// ZWNJ) is rendered exactly as stored.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.field,
    required this.appearance,
    this.style,
    this.textAlign,
  });

  final String text;
  final HighlightField field;
  final CardAppearance appearance;
  final TextStyle? style;
  final TextAlign? textAlign;

  static final _token = RegExp(r'\S+');

  @override
  Widget build(BuildContext context) {
    final mark = CardPalette.highlight(
      appearance.highlightColor,
      Theme.of(context).brightness,
    );
    final marked = TextStyle(backgroundColor: mark);
    final spans = <TextSpan>[];
    if (field == HighlightField.meaning) {
      spans.add(
        TextSpan(
          text: text,
          style: appearance.isHighlighted(field, text) ? marked : null,
        ),
      );
    } else {
      var at = 0;
      for (final m in _token.allMatches(text)) {
        if (m.start > at) {
          spans.add(TextSpan(text: text.substring(at, m.start)));
        }
        final token = m[0]!;
        spans.add(
          TextSpan(
            text: token,
            style: appearance.isHighlighted(field, token) ? marked : null,
          ),
        );
        at = m.end;
      }
      if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textDirection: AutoDirectionText.directionOf(text),
      textAlign: textAlign,
    );
  }
}

/// [base] scaled by [scale] and in the card's ink.
TextStyle? cardTextStyle(
  BuildContext context,
  TextStyle? base,
  CardAppearance appearance,
  double scale,
) {
  if (base == null) return null;
  return base.copyWith(
    fontSize: (base.fontSize ?? 16) * scale,
    color: CardPalette.inkOf(context, appearance),
  );
}
