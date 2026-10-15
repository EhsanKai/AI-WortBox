import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/language/language.dart';
import '../../../core/text/text_normalizer.dart';

/// A named collection of vocabulary with its own language pair and limits.
@immutable
class Deck {
  const Deck({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.definitionLanguage,
    required this.dailyNewCardLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final Language sourceLanguage;
  final Language definitionLanguage;
  final int dailyNewCardLimit;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Deck &&
      other.id == id &&
      other.name == name &&
      other.sourceLanguage == sourceLanguage &&
      other.definitionLanguage == definitionLanguage &&
      other.dailyNewCardLimit == dailyNewCardLimit &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceLanguage,
    definitionLanguage,
    dailyNewCardLimit,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Deck($id, $name)';
}

/// A deck with aggregate counts, for list and dashboard display.
@immutable
class DeckSummary {
  const DeckSummary({required this.deck, required this.entryCount});

  final Deck deck;
  final int entryCount;

  @override
  bool operator ==(Object other) =>
      other is DeckSummary &&
      other.deck == deck &&
      other.entryCount == entryCount;

  @override
  int get hashCode => Object.hash(deck, entryCount);
}

/// User input for creating a deck. Defaults to German → Persian.
@immutable
class DeckDraft {
  const DeckDraft({
    required this.name,
    this.sourceLanguage = AppConfig.defaultSourceLanguage,
    this.definitionLanguage = AppConfig.defaultDefinitionLanguage,
    this.dailyNewCardLimit = AppConfig.defaultDailyNewCardLimit,
  });

  final String name;
  final Language sourceLanguage;
  final Language definitionLanguage;
  final int dailyNewCardLimit;

  /// The name as it will be stored: composed characters, collapsed spaces.
  String get cleanedName => TextNormalizer.cleanName(name);

  /// Validation rules that do not need the database. Name uniqueness is
  /// checked by the repository.
  Set<DeckValidationError> validate() {
    final errors = <DeckValidationError>{};
    final cleaned = cleanedName;
    if (cleaned.isEmpty) {
      errors.add(DeckValidationError.nameEmpty);
    } else if (cleaned.runes.length > AppConfig.maxDeckNameLength) {
      errors.add(DeckValidationError.nameTooLong);
    }
    if (dailyNewCardLimit < AppConfig.minDailyNewCardLimit ||
        dailyNewCardLimit > AppConfig.maxDailyNewCardLimit) {
      errors.add(DeckValidationError.dailyLimitOutOfRange);
    }
    if (!sourceLanguage.isSupported || !definitionLanguage.isSupported) {
      errors.add(DeckValidationError.unsupportedLanguage);
    }
    if (sourceLanguage == definitionLanguage) {
      errors.add(DeckValidationError.identicalLanguages);
    }
    return errors;
  }
}
