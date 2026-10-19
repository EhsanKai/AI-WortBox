/// Conversion between Anki field HTML and plain text.
abstract final class AnkiHtml {
  static final _lineBreaks = RegExp(
    r'<br\s*/?>|</(div|p|li|tr|h[1-6])\s*>',
    caseSensitive: false,
  );
  static final _tags = RegExp(r'<[^>]*>');
  static final _sound = RegExp(r'\[sound:[^\]]*\]');
  static final _cloze = RegExp(r'\{\{c\d+::(.*?)(?:::[^}]*)?\}\}');
  static final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);');
  static final _spaces = RegExp(r'[ \t ]+');

  static const _named = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'zwnj': '‌',
    'zwj': '‍',
    'lrm': '‎',
    'rlm': '‏',
    'shy': '',
  };

  /// Plain text of an Anki field: line breaks for `<br>` and block ends,
  /// other tags removed (images included), `[sound:…]` removed, cloze
  /// markers reduced to their text, HTML entities decoded, spaces collapsed
  /// and blank lines dropped.
  static String toText(String html) {
    final text = html
        .replaceAll(_lineBreaks, '\n')
        .replaceAll(_tags, '')
        .replaceAll(_sound, '')
        .replaceAllMapped(_cloze, (m) => m[1]!)
        .replaceAllMapped(_entity, (m) => _decode(m[1]!) ?? m[0]!);
    return text
        .split('\n')
        .map((line) => line.replaceAll(_spaces, ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static String? _decode(String entity) {
    if (entity.startsWith('#x') || entity.startsWith('#X')) {
      final code = int.tryParse(entity.substring(2), radix: 16);
      return code == null ? null : String.fromCharCode(code);
    }
    if (entity.startsWith('#')) {
      final code = int.tryParse(entity.substring(1));
      return code == null ? null : String.fromCharCode(code);
    }
    return _named[entity];
  }

  /// Field HTML for plain [text]: `& < > "` escaped, line breaks as `<br>`.
  static String fromText(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll(RegExp(r'\r\n|\r|\n'), '<br>');
}
