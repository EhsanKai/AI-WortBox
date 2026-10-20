import 'package:ai_wortbox/features/sentence_practice/domain/sentence_exercise.dart';

const haus = PracticeWord(
  entryId: 'e-haus',
  original: 'Haus',
  lemma: 'Haus',
  partOfSpeech: 'Nomen',
  meanings: ['خانه'],
);

const gehen = PracticeWord(
  entryId: 'e-gehen',
  original: 'gehen',
  meanings: ['رفتن'],
);

/// A valid generated item for [haus].
Map<String, Object?> hausItem([String id = '1']) => {
  'id': id,
  'word': 'Haus',
  'german': 'Unser Haus hat einen großen Garten.',
  'persian': 'خانهٔ ما باغ بزرگی دارد.',
  'usedForm': 'Haus',
};

/// A valid generated item for [gehen], with an irregular form.
Map<String, Object?> gehenItem([String id = '2']) => {
  'id': id,
  'word': 'gehen',
  'german': 'Gestern ging ich früh nach Hause.',
  'persian': 'دیروز زود به خانه رفتم.',
  'usedForm': 'ging',
};

/// Valid feedback JSON.
Map<String, Object?> feedbackContent({
  String verdict = 'minor_errors',
  String targetWord = 'correct',
  List<Map<String, Object?>> corrections = const [
    {
      'type': 'capitalization',
      'original': 'haus',
      'corrected': 'Haus',
      'explanation': 'اسم‌ها در آلمانی با حرف بزرگ نوشته می‌شوند.',
    },
  ],
  String? correctedAnswer = 'Unser Haus hat einen großen Garten.',
  String? naturalVersion = 'Unser Haus hat einen großen Garten.',
  String explanation = 'اسم «Haus» باید با حرف بزرگ نوشته شود.',
}) => {
  'verdict': verdict,
  'targetWord': targetWord,
  'corrections': corrections,
  'correctedAnswer': correctedAnswer,
  'naturalVersion': naturalVersion,
  'explanation': explanation,
};
