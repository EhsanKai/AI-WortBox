import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/language/language.dart';

/// What is sent for one entry: only the word, its sentence context and the
/// meanings it already has (so they are not suggested again). No other user
/// data leaves the device.
@immutable
class EnrichmentRequest {
  const EnrichmentRequest({
    required this.original,
    required this.sourceLanguage,
    required this.definitionLanguage,
    this.sourceContext,
    this.existingMeanings = const [],
  });

  /// The German word or expression, exactly as stored.
  final String original;

  /// The sentence it was found in (scan/import), if any.
  final String? sourceContext;

  final List<String> existingMeanings;
  final Language sourceLanguage;
  final Language definitionLanguage;
}

@immutable
class ProposedMeaning {
  const ProposedMeaning(this.text, {this.explanation});

  /// In the definition language (Persian).
  final String text;
  final String? explanation;

  @override
  bool operator ==(Object other) =>
      other is ProposedMeaning &&
      other.text == text &&
      other.explanation == explanation;

  @override
  int get hashCode => Object.hash(text, explanation);
}

/// A validated AI suggestion for one entry. Nothing is saved until the user
/// reviews it.
@immutable
class EnrichmentProposal {
  const EnrichmentProposal({
    required this.meanings,
    required this.provider,
    required this.model,
    required this.generatedAt,
    this.partOfSpeech,
    this.grammarInfo,
    this.lemma,
    this.exampleSentence,
    this.exampleTranslation,
    this.isAmbiguous = false,
    this.costUsd,
  });

  /// At least one, in the definition language; the first matches the
  /// sentence context when one was given.
  final List<ProposedMeaning> meanings;

  /// German label, e.g. "Nomen", "Verb".
  final String? partOfSpeech;
  final String? grammarInfo;

  /// Dictionary form, only when it differs from the original.
  final String? lemma;

  /// German example and its Persian translation; both or neither.
  final String? exampleSentence;
  final String? exampleTranslation;

  /// The model said the sense is unclear from the context.
  final bool isAmbiguous;

  final String provider;

  /// The model that actually answered.
  final String model;

  /// UTC.
  final DateTime generatedAt;

  /// Cost reported by the provider for this request, if it reported one.
  /// Never estimated.
  final double? costUsd;
}

/// Lets the user stop a running request or batch.
class EnrichmentCancellation {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Provider-neutral AI enrichment.
///
/// The current implementation calls OpenRouter directly with the user's own
/// key; a backend-based implementation can replace it without changing the
/// UI or the review/save logic.
///
/// Throws `EnrichmentException` for every expected failure.
abstract interface class VocabularyEnrichmentService {
  Future<EnrichmentProposal> enrich(
    EnrichmentRequest request, {
    EnrichmentCancellation? cancellation,
  });
}
