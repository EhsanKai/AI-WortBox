import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/text/bidi.dart';
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
            scrollable: true,
            title: Text(l10n.duplicateRedundantTitle),
            icon: const Icon(Icons.inventory_2_outlined),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.duplicateRedundantBody(bidiIsolate(word))),
                const SizedBox(height: AppSpace.xl),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, OpenExisting(existing)),
                  child: Text(l10n.duplicateOpenExisting),
                ),
                if (isEditing) ...[
                  const SizedBox(height: AppSpace.sm),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, const SaveAsNew()),
                    child: Text(l10n.duplicateSaveAnyway),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                TextButton(
                  onPressed: () => Navigator.pop(context, const CancelSave()),
                  child: Text(l10n.actionCancel),
                ),
              ],
            ),
          );
        case SameWordDifferentMeanings(:final existing):
          final first = existing.first;
          return AlertDialog(
            scrollable: true,
            icon: const Icon(Icons.call_split),
            title: Text(l10n.duplicateDifferentTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.duplicateDifferentBody(bidiIsolate(word))),
                const SizedBox(height: AppSpace.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AutoDirectionText(word, style: AppTypography.wordTitle),
                        const SizedBox(height: AppSpace.xs),
                        for (final entry in existing)
                          for (final meaning in entry.meanings)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpace.xs,
                              ),
                              child: AutoDirectionText(
                                '• ${meaning.text}',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                // Actions scroll with the content: the labels are long and
                // must stay reachable with large text on small screens.
                const SizedBox(height: AppSpace.xl),
                FilledButton(
                  onPressed: () => Navigator.pop(context, const SaveAsNew()),
                  child: Text(
                    isEditing
                        ? l10n.duplicateSaveAnyway
                        : l10n.duplicateSaveSeparate,
                  ),
                ),
                if (!isEditing) ...[
                  const SizedBox(height: AppSpace.sm),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, AddMeaningsToExisting(first)),
                    child: Text(l10n.duplicateAddMeanings),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                TextButton(
                  onPressed: () => Navigator.pop(context, const CancelSave()),
                  child: Text(l10n.actionCancel),
                ),
              ],
            ),
          );
      }
    },
  );
  return choice ?? const CancelSave();
}
