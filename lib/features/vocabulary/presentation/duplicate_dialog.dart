import 'package:flutter/material.dart';

import '../../../core/widgets/auto_direction_text.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/duplicate_detection.dart';
import '../domain/vocabulary_entry.dart';

/// What the user decided after a duplicate was detected.
sealed class DuplicateChoice {
  const DuplicateChoice();
}

final class CancelSave extends DuplicateChoice {
  const CancelSave();
}

final class SaveAsNew extends DuplicateChoice {
  const SaveAsNew();
}

final class OpenExisting extends DuplicateChoice {
  const OpenExisting(this.entry);

  final VocabularyEntry entry;
}

final class AddMeaningsToExisting extends DuplicateChoice {
  const AddMeaningsToExisting(this.entry);

  final VocabularyEntry entry;
}

/// Asks how to handle a duplicate. Never merges without an explicit choice.
///
/// When [isEditing] is true, merging into another entry is not offered
/// (it would leave the edited entry behind).
Future<DuplicateChoice> showDuplicateDialog(
  BuildContext context, {
  required DuplicateCheck check,
  required String word,
  required bool isEditing,
}) async {
  if (check is NoDuplicate) return const SaveAsNew();
  final l10n = AppLocalizations.of(context);
  final choice = await showDialog<DuplicateChoice>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      switch (check) {
        case NoDuplicate():
          throw StateError('No duplicate to resolve');
        case RedundantDuplicate(:final existing):
          return AlertDialog(
            title: Text(l10n.duplicateRedundantTitle),
            content: Text(l10n.duplicateRedundantBody(word)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, const CancelSave()),
                child: Text(l10n.actionCancel),
              ),
              if (isEditing)
                TextButton(
                  onPressed: () => Navigator.pop(context, const SaveAsNew()),
                  child: Text(l10n.duplicateSaveAnyway),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(context, OpenExisting(existing)),
                child: Text(l10n.duplicateOpenExisting),
              ),
            ],
          );
        case SameWordDifferentMeanings(:final existing):
          final first = existing.first;
          return AlertDialog(
            title: Text(l10n.duplicateDifferentTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.duplicateDifferentBody(word)),
                  const SizedBox(height: 12),
                  for (final entry in existing)
                    for (final meaning in entry.meanings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: AutoDirectionText(
                          '• ${meaning.text}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                ],
              ),
            ),
            actionsOverflowDirection: VerticalDirection.up,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, const CancelSave()),
                child: Text(l10n.actionCancel),
              ),
              if (!isEditing)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, AddMeaningsToExisting(first)),
                  child: Text(l10n.duplicateAddMeanings),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(context, const SaveAsNew()),
                child: Text(
                  isEditing
                      ? l10n.duplicateSaveAnyway
                      : l10n.duplicateSaveSeparate,
                ),
              ),
            ],
          );
      }
    },
  );
  return choice ?? const CancelSave();
}
