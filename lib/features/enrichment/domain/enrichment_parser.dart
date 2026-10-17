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
  'properties': {
    'meanings': {
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
    },
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
  },
};

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
/// - control characters are removed and whitespace is collapsed.
///
/// Throws [EnrichmentException] (`malformedResponse`) when nothing usable
/// remains (no valid meaning).
abstract final class EnrichmentParser {
  static final _controlChars = RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F]');

  static ParsedEnrichment parse(String content, {required String original}) {
    final map = _decode(content);
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

    final pos = map['partOfSpeech'];
    return ParsedEnrichment(
      meanings: List.unmodifiable(meanings),
      partOfSpeech: pos is String ? partOfSpeechLabels[pos] : null,
      grammarInfo: _text(map['grammarInfo'], AppConfig.maxTextFieldLength),
      lemma: lemma,
      exampleSentence: example,
      exampleTranslation: translation,
      isAmbiguous: map['isAmbiguous'] == true,
    );
  }

  static Map<String, Object?> _decode(String content) {
    var text = content.trim();
    // Some models wrap JSON in a Markdown code fence despite the schema.
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fence.firstMatch(text);
    if (match != null) text = match.group(1)!;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return decoded.cast<String, Object?>();
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
