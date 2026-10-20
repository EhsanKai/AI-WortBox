import '../../../core/error/app_exception.dart';
import '../../../core/text/script_detector.dart';
import '../../../core/text/text_normalizer.dart';
import '../../enrichment/domain/enrichment_parser.dart';
import 'sentence_exercise.dart';
import 'target_word_matcher.dart';

/// Validates model answers for sentence practice. Everything the model
/// returns is untrusted: an item is used only when it passes every check.
abstract final class SentencePracticeParser {
  static const maxSentenceLength = 300;
  static const maxTranslationLength = 400;
  static const maxExplanationLength = 600;
  static const maxCorrections = 5;

  static final _controlChars = RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F]');

  /// Three Latin words in a row: a German sentence inside the Persian text
  /// would give the answer away. A single German word in brackets (often
  /// the target word, which is shown anyway) is harmless.
  static final _latinRun = RegExp(
    r'[A-Za-zÄÖÜäöüß]{2,}[\s,.;:!?-]+[A-Za-zÄÖÜäöüß]{2,}[\s,.;:!?-]+'
    r'[A-Za-zÄÖÜäöüß]{2,}',
  );

  /// Parses generated exercises for [words] (ids `1`..`n` in order). An
  /// item that is missing, about another word, or fails a check is
  /// reported in [GeneratedExercises.rejected], with content-free reasons
  /// in [GeneratedExercises.rejectionSummary]. Throws `malformedResponse`
  /// (`noUsableItems`) when no item is usable, and (`notJson`,
  /// `unexpectedShape`) when the answer is unusable as a whole.
  static GeneratedExercises parseExercises(
    String content,
    List<PracticeWord> words,
  ) {
    final decoded = EnrichmentParser.decodeJson(content);
    final items = switch (decoded) {
      {'items': final List<Object?> list} => list,
      {'exercises': final List<Object?> list} => list,
      final List<Object?> list => list,
      // A single exercise without the list around it.
      final Map<Object?, Object?> one when words.length == 1 => [
        {'id': '1', ...one},
      ],
      _ => throw const EnrichmentException(
        EnrichmentError.malformedResponse,
        problem: ResponseProblem.unexpectedShape,
      ),
    };
    final byId = <String, Map<String, Object?>>{};
    final duplicated = <String>{};
    for (final raw in items) {
      if (raw is! Map) continue;
      // Some models return the id as a number.
      final id = switch (raw['id']) {
        final String s => s.trim(),
        final num n when n == n.toInt() => '${n.toInt()}',
        _ => null,
      };
      if (id == null) continue;
      if (byId.containsKey(id)) duplicated.add(id);
      byId[id] = raw.cast<String, Object?>();
    }
    final exercises = <SentenceExercise>[];
    final rejected = <PracticeWord>[];
    final reasons = <ExerciseRejection, int>{};
    for (final (i, word) in words.indexed) {
      final id = '${i + 1}';
      final item = byId[id];
      final result = item == null
          ? ExerciseRejection.missing
          : duplicated.contains(id)
          ? ExerciseRejection.duplicate
          : _exercise(item, word);
      if (result is SentenceExercise) {
        exercises.add(result);
      } else {
        rejected.add(word);
        final reason = result as ExerciseRejection;
        reasons[reason] = (reasons[reason] ?? 0) + 1;
      }
    }
    final summary = [
      'usable ${exercises.length}/${words.length}',
      for (final MapEntry(:key, :value) in reasons.entries)
        '${key.name}×$value',
    ].join(', ');
    if (exercises.isEmpty) {
      throw EnrichmentException(
        EnrichmentError.malformedResponse,
        problem: ResponseProblem.noUsableItems,
        detail: summary,
      );
    }
    return GeneratedExercises(
      exercises,
      rejected: rejected,
      rejectionSummary: rejected.isEmpty ? null : summary,
    );
  }

  /// A [SentenceExercise], or the [ExerciseRejection] why not.
  static Object _exercise(Map<String, Object?> item, PracticeWord word) {
    // The answer must be about the word that was asked for: the echoed
    // word must be that word (articles, case and added forms aside).
    final echoed = _text(item['word'], 200);
    if (echoed != null &&
        TextNormalizer.vocabularyKey(echoed) !=
            TextNormalizer.vocabularyKey(word.original) &&
        !TargetWordMatcher.matches(echoed, word.original, lemma: word.lemma)) {
      return ExerciseRejection.otherWord;
    }
    final german = _text(item['german'] ?? item['sentence'], maxSentenceLength);
    final persian = _text(
      item['persian'] ?? item['translation'],
      maxTranslationLength,
    );
    if (german == null || persian == null) {
      return ExerciseRejection.missingFields;
    }
    if (!ScriptDetector.isMostlyLatin(german)) {
      return ExerciseRejection.germanNotGerman;
    }
    if (!ScriptDetector.isMostlyRtl(persian)) {
      return ExerciseRejection.persianNotPersian;
    }
    // The sentence must really contain the word, recognisably.
    final found = TargetWordMatcher.formIn(
      german,
      word.original,
      lemma: word.lemma,
    );
    if (found == null) return ExerciseRejection.targetWordMissing;
    // The reported form is used when it is in the sentence; otherwise the
    // form found there.
    final reported = _text(item['usedForm'], 200);
    final sentenceWords = {
      for (final w in TargetWordMatcher.words(german))
        TargetWordMatcher.fold(w),
    };
    final reportedWords = reported == null
        ? const <String>[]
        : TargetWordMatcher.words(reported);
    final usedForm =
        reportedWords.isNotEmpty &&
            reportedWords.every(
              (w) => sentenceWords.contains(TargetWordMatcher.fold(w)),
            )
        ? reported!
        : found;
    // The Persian text must not contain the German sentence.
    if (_latinRun.hasMatch(persian)) return ExerciseRejection.revealsAnswer;
    return SentenceExercise(
      word: word,
      german: german,
      persian: persian,
      usedForm: usedForm,
    );
  }

  /// Parses feedback on an answer. Throws `malformedResponse` when it is
  /// incomplete, invalid or contradicts itself.
  static SentenceFeedback parseFeedback(String content) {
    final decoded = EnrichmentParser.decodeJson(content);
    if (decoded is! Map) _malformed();
    final json = decoded.cast<String, Object?>();
    final verdict = _enum(json['verdict'], const {
      'correct': SentenceVerdict.correct,
      'acceptable': SentenceVerdict.acceptable,
      'minor_errors': SentenceVerdict.minorErrors,
      'incorrect': SentenceVerdict.incorrect,
    });
    final target = _enum(json['targetWord'], const {
      'correct': TargetWordUse.correct,
      'incorrect': TargetWordUse.incorrect,
      'missing': TargetWordUse.missing,
    });
    final explanation = _text(json['explanation'], maxExplanationLength);
    if (verdict == null || target == null || explanation == null) {
      _malformed();
    }
    if (!ScriptDetector.isMostlyRtl(explanation)) _malformed();
    // A correct answer cannot have left out or misused the target word.
    if ((verdict == SentenceVerdict.correct ||
            verdict == SentenceVerdict.acceptable) &&
        target != TargetWordUse.correct) {
      _malformed();
    }
    final corrections = <SentenceCorrection>[];
    final rawCorrections = json['corrections'];
    if (rawCorrections is List) {
      for (final raw in rawCorrections) {
        if (corrections.length >= maxCorrections) break;
        if (raw is! Map) continue;
        final kind = _enum(raw['type'], const {
          'grammar': CorrectionKind.grammar,
          'word_order': CorrectionKind.wordOrder,
          'spelling': CorrectionKind.spelling,
          'capitalization': CorrectionKind.capitalization,
          'vocabulary': CorrectionKind.vocabulary,
          'meaning': CorrectionKind.meaning,
        });
        final original = _text(raw['original'], maxSentenceLength);
        final corrected = _text(raw['corrected'], maxSentenceLength);
        if (kind == null || original == null || corrected == null) continue;
        if (original == corrected) continue;
        corrections.add(
          SentenceCorrection(
            kind: kind,
            original: original,
            corrected: corrected,
            explanation: _text(raw['explanation'], maxExplanationLength),
          ),
        );
      }
    }
    return SentenceFeedback(
      verdict: verdict,
      targetWord: target,
      explanation: explanation,
      corrections: corrections,
      correctedAnswer: _text(json['correctedAnswer'], maxTranslationLength),
      naturalVersion: _text(json['naturalVersion'], maxTranslationLength),
    );
  }

  static Never _malformed() =>
      throw const EnrichmentException(EnrichmentError.malformedResponse);

  static T? _enum<T>(Object? value, Map<String, T> values) =>
      value is String ? values[value.trim().toLowerCase()] : null;

  static String? _text(Object? value, int maxLength) {
    if (value is! String) return null;
    final cleaned = TextNormalizer.collapseWhitespace(
      value.replaceAll(_controlChars, ''),
    );
    if (cleaned.isEmpty || cleaned.runes.length > maxLength) return null;
    return cleaned;
  }
}
