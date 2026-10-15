import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Text whose direction follows its content rather than the UI locale.
///
/// Use for user-provided strings (deck names, German words, Persian meanings)
/// so that a German phrase inside the right-to-left Persian UI keeps its
/// punctuation and word order intact, and vice versa.
class AutoDirectionText extends StatelessWidget {
  const AutoDirectionText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  static TextDirection directionOf(String text) =>
      intl.Bidi.detectRtlDirectionality(text)
      ? TextDirection.rtl
      : TextDirection.ltr;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: directionOf(text),
      // Keep alignment tied to the surrounding layout, not the text, so that
      // lists stay visually aligned in the RTL UI.
      textAlign:
          textAlign ??
          (Directionality.of(context) == TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left),
    );
  }
}
