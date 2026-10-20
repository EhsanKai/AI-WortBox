import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/script_detector.dart';
import '../../../core/text/text_normalizer.dart';
import 'enrichment.dart';

/// Part-of-speech values the model may return, mapped to the German labels
/// the app stores (the same labels users type in the form).
const partOfSpeechLabels = {
  'noun': 'Nomen',
  'verb': 'Verb',
  'adjective': 'Adjektiv',
  'adverb': 'Adverb',
  'pronoun': 'Pronomen',
  'preposition': 'Präposition',
  'conjunction': 'Konjunktion',
  'interjection': 'Interjektion',
  'numeral': 'Numerale',
  'article': 'Artikel',
  'particle': 'Partikel',
  'phrase': 'Redewendung',
};

/// JSON Schema for the structured response (strict mode: every property is
/// required, optional values are nullable, no extra properties).
const Map<String, Object?> enrichmentResponseSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'meanings',
    'partOfSpeech',
    'grammarInfo',
    'lemma',
    'exampleSentence',
    'exampleTranslation',
    'isAmbiguous',
  ],
  'properties': _fieldSchemas,
};

/// JSON Schema for a batch: one item per requested word, echoing its `id`
/// and `word` so that answers are matched to words, never by position.
const Map<String, Object?> batchEnrichmentResponseSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['items'],
  'properties': {
    'items': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['id', 'word', ..._fieldNames],
        'properties': {
          'id': {'type': 'string'},
          'word': {'type': 'string'},
          ..._fieldSchemas,
        },
      },
    },
  },
};

/// JSON Schema for a meanings-only batch ([EnrichmentScope.meanings]): the
/// id, the echoed word, the meanings and the ambiguity hint, nothing else.
const Map<String, Object?> meaningsBatchResponseSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['items'],
  'properties': {
    'items': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['id', 'word', 'meanings', 'isAmbiguous'],
        'properties': {
          'id': {'type': 'string'},
          'word': {'type': 'string'},
          'meanings': _meaningsSchema,
          'isAmbiguous': {'type': 'boolean'},
        },
      },
    },
  },
};

const _fieldNames = [
  'meanings',
  'partOfSpeech',
  'grammarInfo',
  'lemma',
  'exampleSentence',
  'exampleTranslation',
  'isAmbiguous',
];

const Map<String, Object?> _meaningsSchema = {
  'type': 'array',
  'description':
      'Persian (Farsi) meanings in Persian script; the first one is the '
      'sense used in the sentence context.',
  'items': {
    'type': 'object',
    'additionalProperties': false,
    'required': ['text', 'explanation'],
    'properties': {
      'text': {'type': 'string'},
      'explanation': {
        'type': ['string', 'null'],
      },
    },
  },
};

const Map<String, Object?> _fieldSchemas = {
  'meanings': _meaningsSchema,
  'partOfSpeech': {
    'type': ['string', 'null'],
    'enum': [
      'noun',
      'verb',
      'adjective',
      'adverb',
      'pronoun',
      'preposition',
      'conjunction',
      'interjection',
      'numeral',
      'article',
      'particle',
      'phrase',
      null,
    ],
  },
  'grammarInfo': {
    'type': ['string', 'null'],
  },
  'lemma': {
    'type': ['string', 'null'],
  },
  'exampleSentence': {
    'type': ['string', 'null'],
  },
  'exampleTranslation': {
    'type': ['string', 'null'],
  },
  'isAmbiguous': {'type': 'boolean'},
};

/// One requested word in a batch.
typedef BatchWord = ({String id, String original});

/// The content fields of a proposal, after validation.
@immutable
class ParsedEnrichment {
  const ParsedEnrichment({
    required this.meanings,
    this.partOfSpeech,
    this.grammarInfo,
    this.lemma,
    this.exampleSentence,
    this.exampleTranslation,
    this.isAmbiguous = false,
  });

  final List<ProposedMeaning> meanings;
  final String? partOfSpeech;
  final String? grammarInfo;
  final String? lemma;
  final String? exampleSentence;
  final String? exampleTranslation;
  final bool isAmbiguous;
}

/// Validates model output. Never trusts it:
///
/// - the whole response must be one JSON object (code fences are tolerated);
/// - meanings must be Persian, examples German with a Persian translation,
///   the lemma German; anything else is dropped;
/// - lengths are limited to the same bounds as user input;
/// - control characters are removed and whitespace is collapsed;
/// - grammar that contradicts itself is dropped rather than saved (see
///   [_checkGrammar]): no grammar note without a word class, noun notes
///   must give the article, nouns must be capitalised, verb lemmas must
///   look like infinitives.
///
/// Throws [EnrichmentException] (`malformedResponse`) when nothing usable
/// remains (no valid meaning).
abstract final class EnrichmentParser {
  static final _controlChars = RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F]');

  /// Longest grammar note accepted ("short note").
  static const maxGrammarLength = 200;

  static ParsedEnrichment parse(String content, {required String original}) {
    final map = _decode(content);
    if (map is! Map) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    return parseMap(map.cast<String, Object?>(), original: original);
  }

  /// Validates a batch answer. Returns, per requested word id, either a
  /// [ParsedEnrichment] or the [EnrichmentException] for that word alone
  /// (missing, mismatched or invalid), so one bad item never discards the
  /// others. Throws `malformedResponse` only when the answer as a whole is
  /// unusable.
  ///
  /// Items are matched by `id` and must echo the requested `word`; an item
  /// without an id is accepted only when its word identifies exactly one
  /// requested word. Unknown ids are ignored. A word answered by more than
  /// one item is rejected (it is unclear which answer is meant).
  ///
  /// With [meaningsOnly], only meanings and the ambiguity hint are kept;
  /// any other field in the answer is discarded.
  static Map<String, Object> parseBatch(
    String content,
    List<BatchWord> words, {
    bool meaningsOnly = false,
  }) {
    final decoded = _decode(content);
    final List<Object?> items;
    if (decoded is Map && decoded['items'] is List) {
      items = decoded['items']! as List;
    } else if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && words.length == 1) {
      // A single-word answer without the batch wrapper.
      items = [
        {...decoded, 'id': words.single.id, 'word': words.single.original},
      ];
    } else {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }

    String key(String s) => TextNormalizer.vocabularyKey(s);
    final byId = {for (final w in words) w.id: w};
    final results = <String, Object>{};
    final answered = <String>{};
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = raw.cast<String, Object?>();
      final word = item['word'];
      if (word is! String) continue;
      var target = item['id'] is String ? byId[item['id']! as String] : null;
      if (target == null && item['id'] == null) {
        final matches = [
          for (final w in words)
            if (key(w.original) == key(word)) w,
        ];
        if (matches.length == 1) target = matches.single;
      }
      // The answer must be about the word that was asked for.
      if (target == null || key(target.original) != key(word)) continue;
      if (!answered.add(target.id)) {
        results[target.id] = const EnrichmentException(
          EnrichmentError.malformedResponse,
        );
        continue;
      }
      try {
        results[target.id] = parseMap(
          item,
          original: target.original,
          meaningsOnly: meaningsOnly,
        );
      } on EnrichmentException catch (e) {
        results[target.id] = e;
      }
    }
    for (final w in words) {
      results.putIfAbsent(
        w.id,
        () => const EnrichmentException(EnrichmentError.malformedResponse),
      );
    }
    if (!results.values.any((r) => r is ParsedEnrichment)) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    return results;
  }

  /// Validates one decoded answer object for [original].
  static ParsedEnrichment parseMap(
    Map<String, Object?> map, {
    required String original,
    bool meaningsOnly = false,
  }) {
    final meanings = <ProposedMeaning>[];
    final seen = <String>{};
    final rawMeanings = map['meanings'];
    if (rawMeanings is List) {
      for (final raw in rawMeanings) {
        if (meanings.length >= AppConfig.aiMaxMeanings) break;
        if (raw is! Map) continue;
        final text = _persian(raw['text'], AppConfig.maxMeaningLength);
        if (text == null || !seen.add(TextNormalizer.meaningKey(text))) {
          continue;
        }
        meanings.add(
          ProposedMeaning(
            text,
            explanation: _persian(
              raw['explanation'],
              AppConfig.maxMeaningLength,
            ),
          ),
        );
      }
    }
    if (meanings.isEmpty) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    if (meaningsOnly) {
      return ParsedEnrichment(
        meanings: List.unmodifiable(meanings),
        isAmbiguous: map['isAmbiguous'] == true,
      );
    }

    var example = _german(map['exampleSentence'], AppConfig.maxTextFieldLength);
    var translation = _persian(
      map['exampleTranslation'],
      AppConfig.maxTextFieldLength,
    );
    if (example == null || translation == null) {
      example = null;
      translation = null;
    }

    var lemma = _german(map['lemma'], AppConfig.maxOriginalLength);
    if (lemma != null &&
        TextNormalizer.vocabularyKey(lemma) ==
            TextNormalizer.vocabularyKey(original)) {
      lemma = null;
    }

    final rawPos = map['partOfSpeech'];
    final grammar = _checkGrammar(
      pos: rawPos is String && partOfSpeechLabels.containsKey(rawPos)
          ? rawPos
          : null,
      grammar: _german(map['grammarInfo'], maxGrammarLength),
      lemma: lemma,
      original: original,
    );
    return ParsedEnrichment(
      meanings: List.unmodifiable(meanings),
      partOfSpeech: grammar.pos == null
          ? null
          : partOfSpeechLabels[grammar.pos!],
      grammarInfo: grammar.grammar,
      lemma: grammar.lemma,
      exampleSentence: example,
      exampleTranslation: translation,
      isAmbiguous: map['isAmbiguous'] == true,
    );
  }

  static final _article = RegExp(r'^(der|die|das)\b', caseSensitive: false);
  static final _articleNoun = RegExp(r'^(der|die|das)\s+\p{Lu}', unicode: true);
  static final _startsUpper = RegExp(r'^\p{Lu}', unicode: true);

  /// Drops grammatical information that is unverifiable or contradicts
  /// itself, instead of saving a likely hallucination:
  /// - no word class → no grammar note (nothing to check it against);
  /// - a noun must be capitalised (lemma or word), else word class and
  ///   note are both dropped; its note must start with the article;
  /// - a note that starts like a noun entry ("der Tisch") is dropped for
  ///   any other word class;
  /// - a verb lemma must end in -n (German infinitives: gehen, tun, sein);
  ///   a noun lemma must be capitalised.
  static ({String? pos, String? grammar, String? lemma}) _checkGrammar({
    required String? pos,
    required String? grammar,
    required String? lemma,
    required String original,
  }) {
    var g = grammar;
    var l = lemma;
    var p = pos;
    final head = (l ?? original).trim();
    if (p == 'noun' && !_startsUpper.hasMatch(head)) {
      p = null;
      g = null;
    }
    if (p == null) g = null;
    if (p == 'noun' && g != null && !_article.hasMatch(g)) g = null;
    if (p != null && p != 'noun' && g != null && _articleNoun.hasMatch(g)) {
      g = null;
    }
    if (l case final value?) {
      final last = value.split(RegExp(r'\s+')).last;
      if ((p == 'verb' && !last.endsWith('n')) ||
          (p == 'noun' && !_startsUpper.hasMatch(value))) {
        l = null;
      }
    }
    return (pos: p, grammar: g, lemma: l);
  }

  /// Decodes a model's JSON answer (also inside a Markdown code fence).
  /// Throws `malformedResponse` when it is not a JSON object or array.
  static Object? decodeJson(String content) => _decode(content);

  static Object? _decode(String content) {
    var text = content.trim();
    // Some models wrap JSON in a Markdown code fence despite the schema.
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fence.firstMatch(text);
    if (match != null) text = match.group(1)!;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map || decoded is List) return decoded;
    } on FormatException {
      // Fall through.
    }
    throw const EnrichmentException(EnrichmentError.malformedResponse);
  }

  static String? _text(Object? value, int maxLength) {
    if (value is! String) return null;
    final cleaned = TextNormalizer.collapseWhitespace(
      value.replaceAll(_controlChars, ''),
    );
    if (cleaned.isEmpty || cleaned.runes.length > maxLength) return null;
    return cleaned;
  }

  static String? _persian(Object? value, int maxLength) {
    final text = _text(value, maxLength);
    return text != null && ScriptDetector.isMostlyRtl(text) ? text : null;
  }

  static String? _german(Object? value, int maxLength) {
    final text = _text(value, maxLength);
    return text != null && ScriptDetector.isMostlyLatin(text) ? text : null;
  }
}
