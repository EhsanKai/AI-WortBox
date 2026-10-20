import 'package:ai_wortbox/app/theme.dart';
import 'package:ai_wortbox/core/design/app_colors.dart';
import 'package:ai_wortbox/features/card_appearance/domain/card_appearance.dart';
import 'package:ai_wortbox/features/card_appearance/presentation/card_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    group('$name theme', () {
      final s = theme.colorScheme;
      final c = theme.extension<AppColors>()!;

      test('text pairs meet WCAG AA (4.5:1)', () {
        final pairs = <String, (Color, Color)>{
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurface/card': (s.onSurface, s.surfaceContainerLow),
          'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
          'onSurfaceVariant/card': (s.onSurfaceVariant, s.surfaceContainerLow),
          'onSurfaceVariant/high': (s.onSurfaceVariant, s.surfaceContainerHigh),
          'onPrimary/primary': (s.onPrimary, s.primary),
          'primary/surface': (s.primary, s.surface),
          'onPrimaryContainer/primaryContainer': (
            s.onPrimaryContainer,
            s.primaryContainer,
          ),
          'onSecondaryContainer/secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer,
          ),
          'tertiary/surface': (s.tertiary, s.surface),
          'onTertiaryContainer/tertiaryContainer': (
            s.onTertiaryContainer,
            s.tertiaryContainer,
          ),
          'error/surface': (s.error, s.surface),
          'onError/error': (s.onError, s.error),
          'onErrorContainer/errorContainer': (
            s.onErrorContainer,
            s.errorContainer,
          ),
          'onInverseSurface/inverseSurface': (
            s.onInverseSurface,
            s.inverseSurface,
          ),
          'onBox/box': (c.onBox, c.box),
          'onHighlight/highlight': (c.onHighlight, c.highlight),
          'onSurface/paper': (s.onSurface, c.paper),
          'onSurface/inputFill': (s.onSurface, c.inputFill),
          'onSurfaceVariant/inputFill': (s.onSurfaceVariant, c.inputFill),
          for (final tone in StatusTone.values)
            'tone.${tone.name}': (
              c.tone(tone).foreground,
              c.tone(tone).background,
            ),
        };
        for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$label on $name',
          );
        }
      });

      test(
        'card appearance: every text colour is readable (4.5:1) on every '
        'card background, the page and answer surfaces and every highlight',
        () {
          final b = theme.brightness;
          final backgrounds = <String, Color>{
            for (final c in CardColor.values)
              'bg.${c.name}':
                  CardPalette.background(c, b) ?? s.surfaceContainerLow,
            'surface': s.surface,
            'answer': s.surfaceContainerHigh,
            for (final h in HighlightColor.values)
              'mark.${h.name}': CardPalette.highlight(h, b),
          };
          for (final ink in CardInk.values) {
            final fg = CardPalette.ink(ink, b) ?? s.onSurface;
            for (final MapEntry(:key, value: bg) in backgrounds.entries) {
              expect(
                contrast(fg, bg),
                greaterThanOrEqualTo(4.5),
                reason: 'ink.${ink.name} on $key ($name)',
              );
            }
          }
        },
      );

      test('input and control outlines meet 3:1', () {
        for (final bg in [s.surface, s.surfaceContainerLow, c.inputFill]) {
          expect(contrast(s.outline, bg), greaterThanOrEqualTo(3));
        }
        // The focused field border and the selected nav indicator.
        expect(contrast(s.primary, c.inputFill), greaterThanOrEqualTo(3));
      });
    });
  }
}
