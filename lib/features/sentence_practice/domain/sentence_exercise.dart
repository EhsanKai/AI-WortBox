import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../enrichment/domain/enrichment.dart' show EnrichmentCancellation;
import '../../vocabulary/domain/vocabulary_entry.dart';
import 'sentence_practice.dart';

/// A saved word as used for sentence practice: only what grounds the
/// exercise (the word, its base form and word class, its saved meanings).
@immutable
class PracticeWord {
  const PracticeWord({
    required this.entryId,
    required this.original,
    required this.meanings,
    this.lemma,
    this.partOfSpeech,
  });

  factory PracticeWord.fromEntry(VocabularyEntry entry) => PracticeWord(
    entryId: entry.id,
    original: entry.original,
    lemma: entry.lemma,
    partOfSpeech: entry.partOfSpeech,
    meanings: [
      for (final m in entry.meanings)
        if (m.text.trim().isNotEmpty) m.text.trim(),
    ],
  );

  final String entryId;

  /// The German word or expression exactly as saved.
  final String original;
  final String? lemma;
  final String? partOfSpeech;

  /// Saved Persian meanings (at least one).
  final List<String> meanings;
}

/// One generated exercise: a German sentence that uses the target word and
/// its Persian translation. Which half is shown depends on the direction;
/// the other half is the model answer, hidden until the learner answers or
/// asks for it.
@immutable
class SentenceExercise {
  const SentenceExercise({
    required this.word,
    required this.german,
    required this.persian,
    required this.usedForm,
  });

  final PracticeWord word;

  /// A natural German sentence containing [usedForm].
  final String german;

  /// Its Persian translation.
  final String persian;

  /// The form of the target word as it appears in [german].
  final String usedForm;

  /// What the learner sees.
  String promptFor(SentencePracticeDirection direction) => switch (direction) {
    SentencePracticeDirection.understand => german,
    SentencePracticeDirection.produce => persian,
  };

  /// The model answer, shown only after an answer or on request.
  String answerFor(SentencePracticeDirection direction) => switch (direction) {
    SentencePracticeDirection.understand => persian,
    SentencePracticeDirection.produce => german,
  };
}

/// The result of generating a session's exercises.
@immutable
class GeneratedExercises {
  const GeneratedExercises(this.exercises, {this.rejected = const []});

  /// Valid exercises, in the order of the requested words.
  final List<SentenceExercise> exercises;

  /// Words whose exercise was missing or failed validation (e.g. the
  /// sentence did not contain the word). They are left out.
  final List<PracticeWord> rejected;
}

/// The overall judgement of an answer.
enum SentenceVerdict {
  /// Correct and natural.
  correct,

  /// Correct, phrased differently from the model answer. Not an error.
  acceptable,

  /// Understandable, with small mistakes.
  minorErrors,

  /// Wrong meaning, wrong or missing target word, or serious errors.
  incorrect;

  SentencePracticeOutcome get outcome => switch (this) {
    correct => SentencePracticeOutcome.correct,
    acceptable => SentencePracticeOutcome.acceptable,
    minorErrors => SentencePracticeOutcome.minorErrors,
    incorrect => SentencePracticeOutcome.incorrect,
  };
}

/// How the learner handled the target word.
enum TargetWordUse { correct, incorrect, missing }

enum CorrectionKind {
  grammar,
  wordOrder,
  spelling,
  capitalization,
  vocabulary,
  meaning,
}

@immutable
class SentenceCorrection {
  const SentenceCorrection({
    required this.kind,
    required this.original,
    required this.corrected,
    this.explanation,
  });

  final CorrectionKind kind;

  /// The learner's text that is wrong.
  final String original;
  final String corrected;

  /// A short Persian explanation.
  final String? explanation;
}

/// Validated feedback on one answer. Nothing of it is stored.
@immutable
class SentenceFeedback {
  const SentenceFeedback({
    required this.verdict,
    required this.targetWord,
    required this.explanation,
    this.corrections = const [],
    this.correctedAnswer,
    this.naturalVersion,
  });

  final SentenceVerdict verdict;
  final TargetWordUse targetWord;

  /// Persian: the most important point (the main mistake, or why the
  /// answer is good).
  final String explanation;
  final List<SentenceCorrection> corrections;

  /// The learner's answer with only the necessary fixes, when it had
  /// mistakes.
  final String? correctedAnswer;

  /// A natural way to say it (German for writing, Persian for
  /// understanding).
  final String? naturalVersion;
}

/// AI behind sentence practice. Generates exercises from saved words and
/// checks answers. Never writes anything.
///
/// Throws [EnrichmentException] for every expected failure (no key, rate
/// limit, network, timeout, invalid answer…).
abstract interface class SentencePracticeAi {
  Future<GeneratedExercises> generate(
    List<PracticeWord> words, {
    required SentencePracticeDirection direction,
    required SentenceLevel level,
    EnrichmentCancellation? cancellation,
  });

  Future<SentenceFeedback> evaluate(
    SentenceExercise exercise,
    String answer, {
    required SentencePracticeDirection direction,
    required SentenceLevel level,
    EnrichmentCancellation? cancellation,
  });
}
