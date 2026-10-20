import '../../scan/domain/lemma_hints.dart';

/// Checks, offline, that a German sentence contains a target word or a
/// grammatical form of it. Used to reject generated sentences that leave
/// the word out.
///
/// The check is deliberately conservative and simple (no dictionary):
/// - each content word of the target (articles, "sich" and short words
///   ignored) must match a word of the sentence;
/// - a sentence word matches when, ignoring case and umlauts, it equals
///   the target word, starts with or contains its stem (the word without a
///   common ending such as -en, -n, -e, -er), or contains the stem without
///   a separable prefix ("fängt … an" for "anfangen");
/// - irregular forms are accepted only when the curated offline list
///   ([LemmaHints]) maps them to the target ("ging" → "gehen").
///
/// A form it cannot recognise makes the exercise fail (it is left out); it
/// never accepts a sentence that lacks every form of the word.
abstract final class TargetWordMatcher {
  static final _word = RegExp(r"[A-Za-zÄÖÜäöüß]+(?:['’-][A-Za-zÄÖÜäöüß]+)*");

  static const _ignored = {
    'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einen', //
    'einem', 'einer', 'eines', 'sich', 'etw', 'jdn', 'jdm', 'jmdn',
    'jmdm', 'jemanden', 'jemandem', 'etwas',
  };

  // No -s/-es: "Haus" must not become "hau" ("Hauptstadt").
  static const _endings = ['ern', 'eln', 'en', 'er', 'e', 'n'];

  static const _separablePrefixes = [
    'zurück', 'zusammen', 'vorbei', 'heraus', 'herein', 'hinaus', //
    'hinein', 'weiter', 'nach', 'fest', 'fort', 'heim', 'her', 'hin',
    'los', 'mit', 'vor', 'weg', 'auf', 'aus', 'bei', 'ein', 'ab', 'an',
    'zu', 'um', 'durch', 'über', 'unter', 'wieder',
  ];

  /// Lower case with umlauts folded (ä → a, ß → ss).
  static String fold(String text) => text
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');

  static List<String> words(String text) => [
    for (final m in _word.allMatches(text)) m[0]!,
  ];

  /// Whether [sentence] contains [original] (or its base form [lemma]) in
  /// some recognisable form.
  static bool matches(String sentence, String original, {String? lemma}) {
    final tokens = words(sentence);
    if (tokens.isEmpty) return false;
    for (final target in {original, ?lemma}) {
      final parts = [
        for (final w in words(target))
          if (!_ignored.contains(w.toLowerCase()) && w.length >= 2) w,
      ];
      if (parts.isEmpty) continue;
      if (parts.every((p) => tokens.any((t) => _sameWord(t, p)))) return true;
    }
    return false;
  }

  /// Whether [token] (from the sentence) is a form of [target].
  static bool _sameWord(String token, String target) {
    final t = fold(token);
    final w = fold(target);
    if (t == w) return true;
    if (LemmaHints.suggest(token)?.baseForm case final base?
        when fold(base) == w) {
      return true;
    }
    for (final stem in _stems(w)) {
      if (stem.length < 3) continue;
      if (t.startsWith(stem)) return true;
      // Participles and other prefixed forms: "gemacht" for "machen".
      if (stem.length >= 4 && t.contains(stem)) return true;
    }
    return false;
  }

  /// The word, the word without a common ending and, for separable verbs,
  /// both without the prefix.
  static Iterable<String> _stems(String word) sync* {
    final bases = <String>{word};
    for (final ending in _endings) {
      if (word.length - ending.length >= 3 && word.endsWith(ending)) {
        bases.add(word.substring(0, word.length - ending.length));
        break;
      }
    }
    for (final base in [...bases]) {
      for (final prefix in _separablePrefixes) {
        final p = fold(prefix);
        if (base.length - p.length >= 3 && base.startsWith(p)) {
          bases.add(base.substring(p.length));
          break;
        }
      }
    }
    yield* bases;
  }
}
