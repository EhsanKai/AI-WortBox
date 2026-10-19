import 'package:flutter/foundation.dart';

import '../../../core/text/script_detector.dart';
import '../../../core/text/text_normalizer.dart';
import 'csv_table.dart';

/// Application field a CSV column can be imported into.
enum ImportField {
  ignore,
  original,
  meaning,
  lemma,
  partOfSpeech,
  exampleSentence,
  exampleTranslation,
  grammarInfo,
  notes,

  /// Tag names, several per cell (see `TagNames.split`).
  tags;

  /// Several columns may map to [meaning]; every other field (except
  /// [ignore]) can be mapped to at most one column.
  bool get allowsMultipleColumns => this == meaning || this == ignore;
}

/// Which field each CSV column is imported into.
@immutable
class ColumnMapping {
  const ColumnMapping({required this.hasHeader, required this.fields});

  /// Whether the first record holds column names rather than data.
  final bool hasHeader;

  /// Field per column index.
  final List<ImportField> fields;

  ImportField fieldOf(int column) =>
      column < fields.length ? fields[column] : ImportField.ignore;

  bool get hasOriginal => fields.contains(ImportField.original);

  bool get hasMeaning => fields.contains(ImportField.meaning);

  /// Assigns [field] to [column]. A single-valued field already assigned to
  /// another column is moved, so the mapping always stays valid.
  ColumnMapping withField(int column, ImportField field) {
    final updated = [...fields];
    while (updated.length <= column) {
      updated.add(ImportField.ignore);
    }
    if (!field.allowsMultipleColumns) {
      for (var i = 0; i < updated.length; i++) {
        if (updated[i] == field) updated[i] = ImportField.ignore;
      }
    }
    updated[column] = field;
    return ColumnMapping(hasHeader: hasHeader, fields: updated);
  }

  /// Exchanges the original and meaning columns (for files whose language
  /// columns are in the other order).
  ColumnMapping swapOriginalAndMeaning() => ColumnMapping(
    hasHeader: hasHeader,
    fields: [
      for (final f in fields)
        switch (f) {
          ImportField.original => ImportField.meaning,
          ImportField.meaning => ImportField.original,
          _ => f,
        },
    ],
  );

  ColumnMapping withHeader(bool value) =>
      ColumnMapping(hasHeader: value, fields: fields);

  @override
  bool operator ==(Object other) =>
      other is ColumnMapping &&
      other.hasHeader == hasHeader &&
      listEquals(other.fields, fields);

  @override
  int get hashCode => Object.hash(hasHeader, Object.hashAll(fields));

  @override
  String toString() => 'ColumnMapping(header: $hasHeader, $fields)';
}

/// Recognizes common column names (English, German and Persian) and suggests
/// an initial mapping.
abstract final class HeaderRecognizer {
  static const Map<String, ImportField> _synonyms = {
    // Source word
    'word': ImportField.original,
    'words': ImportField.original,
    'term': ImportField.original,
    'german': ImportField.original,
    'german word': ImportField.original,
    'deutsch': ImportField.original,
    'de': ImportField.original,
    'wort': ImportField.original,
    'vocabulary': ImportField.original,
    'vocab': ImportField.original,
    'front': ImportField.original,
    'expression': ImportField.original,
    'phrase': ImportField.original,
    'واژه': ImportField.original,
    'لغت': ImportField.original,
    'کلمه': ImportField.original,
    'آلمانی': ImportField.original,
    // Meaning
    'meaning': ImportField.meaning,
    'meanings': ImportField.meaning,
    'translation': ImportField.meaning,
    'persian': ImportField.meaning,
    'farsi': ImportField.meaning,
    'fa': ImportField.meaning,
    'definition': ImportField.meaning,
    'back': ImportField.meaning,
    'bedeutung': ImportField.meaning,
    'übersetzung': ImportField.meaning,
    'معنی': ImportField.meaning,
    'معنا': ImportField.meaning,
    'ترجمه': ImportField.meaning,
    'فارسی': ImportField.meaning,
    // Example sentence
    'example': ImportField.exampleSentence,
    'examples': ImportField.exampleSentence,
    'example sentence': ImportField.exampleSentence,
    'sentence': ImportField.exampleSentence,
    'beispiel': ImportField.exampleSentence,
    'beispielsatz': ImportField.exampleSentence,
    'مثال': ImportField.exampleSentence,
    'جمله': ImportField.exampleSentence,
    // Example translation
    'example translation': ImportField.exampleTranslation,
    'translation of example': ImportField.exampleTranslation,
    'sentence translation': ImportField.exampleTranslation,
    'example fa': ImportField.exampleTranslation,
    'example persian': ImportField.exampleTranslation,
    'ترجمه مثال': ImportField.exampleTranslation,
    'ترجمه جمله': ImportField.exampleTranslation,
    // Lemma
    'lemma': ImportField.lemma,
    'infinitive': ImportField.lemma,
    'grundform': ImportField.lemma,
    // Part of speech
    'pos': ImportField.partOfSpeech,
    'part of speech': ImportField.partOfSpeech,
    'wortart': ImportField.partOfSpeech,
    'نوع کلمه': ImportField.partOfSpeech,
    // Grammar
    'grammar': ImportField.grammarInfo,
    'gender': ImportField.grammarInfo,
    'article': ImportField.grammarInfo,
    'artikel': ImportField.grammarInfo,
    'genus': ImportField.grammarInfo,
    'plural': ImportField.grammarInfo,
    'grammatik': ImportField.grammarInfo,
    'دستور': ImportField.grammarInfo,
    // Notes
    'notes': ImportField.notes,
    'note': ImportField.notes,
    'comment': ImportField.notes,
    'comments': ImportField.notes,
    'notiz': ImportField.notes,
    'notizen': ImportField.notes,
    'یادداشت': ImportField.notes,
    'توضیحات': ImportField.notes,
    // Tags
    'tags': ImportField.tags,
    'tag': ImportField.tags,
    'labels': ImportField.tags,
    'schlagwörter': ImportField.tags,
    'برچسب': ImportField.tags,
    'برچسب ها': ImportField.tags,
    'برچسبها': ImportField.tags,
  };

  static final _separators = RegExp(r'[_\-.:/]+');
  static final _zwnj = RegExp('\u200C');

  /// The field a header cell names, or null if it is not recognized.
  static ImportField? recognize(String header) {
    final key = TextNormalizer.collapseWhitespace(
      TextNormalizer.composeCharacters(header)
          .replaceAll(_separators, ' ')
          .replaceAll(_zwnj, ' ')
          // Drop the Persian ezafe mark: "ترجمهٔ مثال" → "ترجمه مثال"
          .replaceAll('\u0654', '')
          .replaceAll('ۀ', 'ه'),
    ).toLowerCase();
    return _synonyms[key];
  }

  /// Suggests a mapping for [table]:
  ///
  /// - If any cell of the first record is a known column name, the first
  ///   record is a header and recognized columns are mapped.
  /// - Otherwise the first mostly-Latin column becomes the word and the first
  ///   mostly-Persian column the meaning (falling back to columns 1 and 2).
  static ColumnMapping suggest(CsvTable table) {
    final columns = table.columnCount;
    final fields = List.filled(columns, ImportField.ignore);
    if (table.records.isEmpty) {
      return ColumnMapping(hasHeader: false, fields: fields);
    }

    final header = table.records.first;
    final recognized = [
      for (var i = 0; i < columns; i++) recognize(header.cell(i)),
    ];
    if (recognized.any((f) => f != null)) {
      var mapping = ColumnMapping(hasHeader: true, fields: fields);
      for (var i = 0; i < columns; i++) {
        final field = recognized[i];
        if (field == null) continue;
        // Keep the first column for single-valued fields.
        if (!field.allowsMultipleColumns && mapping.fields.contains(field)) {
          continue;
        }
        mapping = mapping.withField(i, field);
      }
      if (!mapping.hasOriginal) {
        final free = mapping.fields.indexOf(ImportField.ignore);
        if (free >= 0) mapping = mapping.withField(free, ImportField.original);
      }
      return mapping;
    }

    final sample = table.records.take(20).toList();
    bool columnIs(int i, bool Function(String) test) {
      final values = sample
          .map((r) => r.cell(i))
          .where((v) => v.trim().isNotEmpty)
          .toList();
      return values.isNotEmpty && values.where(test).length * 2 > values.length;
    }

    var original = -1;
    var meaning = -1;
    for (var i = 0; i < columns; i++) {
      if (original < 0 && columnIs(i, ScriptDetector.isMostlyLatin)) {
        original = i;
      } else if (meaning < 0 && columnIs(i, ScriptDetector.isMostlyRtl)) {
        meaning = i;
      }
    }
    if (original < 0) original = meaning == 0 ? 1 : 0;
    if (meaning < 0 && columns > 1) meaning = original == 0 ? 1 : 0;

    var mapping = ColumnMapping(hasHeader: false, fields: fields);
    if (original < columns) {
      mapping = mapping.withField(original, ImportField.original);
    }
    if (meaning >= 0 && meaning < columns) {
      mapping = mapping.withField(meaning, ImportField.meaning);
    }
    return mapping;
  }
}
