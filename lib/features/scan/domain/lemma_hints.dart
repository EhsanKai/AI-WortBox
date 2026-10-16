import 'package:flutter/foundation.dart';

/// A suggested dictionary form for a selected word. It is only a hint: it is
/// shown to the user, never applied automatically, and the original form is
/// always kept.
@immutable
class LemmaHint {
  const LemmaHint(this.baseForm);

  final String baseForm;

  @override
  bool operator ==(Object other) =>
      other is LemmaHint && other.baseForm == baseForm;

  @override
  int get hashCode => baseForm.hashCode;
}

/// Conservative, offline base-form hints.
///
/// Only inflected forms of common irregular verbs that map to exactly one
/// infinitive are listed. Ambiguous forms (e.g. "gestanden" — stehen or
/// gestehen; "gefallen" — fallen or the verb gefallen; "gelassen" — also an
/// adjective) are deliberately omitted. Regular inflection is not guessed.
abstract final class LemmaHints {
  static const Map<String, String> _irregularForms = {
    // sein
    'bin': 'sein', 'bist': 'sein', 'ist': 'sein', 'sind': 'sein',
    'seid': 'sein', 'war': 'sein', 'warst': 'sein', 'waren': 'sein',
    'wart': 'sein', 'gewesen': 'sein', 'wäre': 'sein', 'wären': 'sein',
    // haben
    'habe': 'haben', 'hast': 'haben', 'hat': 'haben', 'habt': 'haben',
    'hatte': 'haben', 'hattest': 'haben', 'hatten': 'haben',
    'hättest': 'haben', 'hätte': 'haben', 'hätten': 'haben',
    // werden
    'werde': 'werden', 'wirst': 'werden', 'wird': 'werden',
    'werdet': 'werden', 'wurde': 'werden', 'wurden': 'werden',
    'geworden': 'werden', 'würde': 'werden', 'würden': 'werden',
    // modal verbs and wissen
    'kann': 'können', 'kannst': 'können', 'konnte': 'können',
    'konnten': 'können', 'könnte': 'können',
    'muss': 'müssen', 'musst': 'müssen', 'musste': 'müssen',
    'mussten': 'müssen', 'müsste': 'müssen',
    'will': 'wollen', 'willst': 'wollen', 'wollte': 'wollen',
    'wollten': 'wollen',
    'darf': 'dürfen', 'darfst': 'dürfen', 'durfte': 'dürfen',
    'durften': 'dürfen', 'dürfte': 'dürfen',
    'soll': 'sollen', 'sollst': 'sollen', 'sollte': 'sollen',
    'sollten': 'sollen',
    'mag': 'mögen', 'magst': 'mögen', 'mochte': 'mögen', 'möchte': 'mögen',
    'möchtest': 'mögen', 'möchten': 'mögen',
    'weiß': 'wissen', 'weißt': 'wissen', 'wusste': 'wissen',
    'wussten': 'wissen', 'gewusst': 'wissen',
    // common strong and mixed verbs
    'ging': 'gehen', 'gingen': 'gehen', 'gegangen': 'gehen',
    'kam': 'kommen', 'kamen': 'kommen', 'gekommen': 'kommen',
    'sieht': 'sehen', 'siehst': 'sehen', 'sah': 'sehen', 'sahen': 'sehen',
    'gesehen': 'sehen',
    'gibt': 'geben', 'gibst': 'geben', 'gab': 'geben', 'gaben': 'geben',
    'gegeben': 'geben',
    'nimmt': 'nehmen', 'nimmst': 'nehmen', 'nahm': 'nehmen',
    'nahmen': 'nehmen', 'genommen': 'nehmen',
    'fand': 'finden', 'fanden': 'finden', 'gefunden': 'finden',
    'saß': 'sitzen', 'saßen': 'sitzen', 'gesessen': 'sitzen',
    'lief': 'laufen', 'liefen': 'laufen', 'läuft': 'laufen',
    'gelaufen': 'laufen',
    'spricht': 'sprechen', 'sprach': 'sprechen', 'sprachen': 'sprechen',
    'gesprochen': 'sprechen',
    'schrieb': 'schreiben', 'schrieben': 'schreiben',
    'geschrieben': 'schreiben',
    'liest': 'lesen', 'las': 'lesen', 'lasen': 'lesen', 'gelesen': 'lesen',
    'isst': 'essen', 'aß': 'essen', 'aßen': 'essen', 'gegessen': 'essen',
    'trank': 'trinken', 'tranken': 'trinken', 'getrunken': 'trinken',
    'fährt': 'fahren', 'fährst': 'fahren', 'fuhr': 'fahren',
    'fuhren': 'fahren', 'gefahren': 'fahren',
    'blieb': 'bleiben', 'blieben': 'bleiben', 'geblieben': 'bleiben',
    'dachte': 'denken', 'dachten': 'denken', 'gedacht': 'denken',
    'brachte': 'bringen', 'brachten': 'bringen', 'gebracht': 'bringen',
    'tat': 'tun', 'taten': 'tun', 'getan': 'tun',
    'hält': 'halten', 'hielt': 'halten', 'hielten': 'halten',
    'gehalten': 'halten',
    'rief': 'rufen', 'riefen': 'rufen', 'gerufen': 'rufen',
    'trägt': 'tragen', 'trug': 'tragen', 'trugen': 'tragen',
    'getragen': 'tragen',
    'zog': 'ziehen', 'zogen': 'ziehen', 'gezogen': 'ziehen',
    'hilft': 'helfen', 'half': 'helfen', 'halfen': 'helfen',
    'geholfen': 'helfen',
    'starb': 'sterben', 'starben': 'sterben', 'gestorben': 'sterben',
    'wirft': 'werfen', 'warf': 'werfen', 'warfen': 'werfen',
    'geworfen': 'werfen',
    'trifft': 'treffen', 'traf': 'treffen', 'trafen': 'treffen',
    'getroffen': 'treffen',
  };

  /// A hint for a single selected word, or null when no reliable hint exists
  /// (multi-word expressions, unknown or ambiguous forms, or a word that is
  /// already the base form).
  static LemmaHint? suggest(String selected) {
    final word = selected.trim();
    if (word.isEmpty || word.contains(RegExp(r'\s'))) return null;
    final base = _irregularForms[word.toLowerCase()];
    if (base == null || base == word.toLowerCase()) return null;
    return LemmaHint(base);
  }
}
