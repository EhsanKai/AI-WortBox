import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/vocabulary_entry.dart';

/// Vocabulary card in a deck list: the German word in the book face, its
/// Persian meanings below (unless [showMeaning] is false).
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.deckName,
    this.showMeaning = true,
    this.selected,
  });

  final VocabularyEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// False hides the meanings, e.g. in a deck before reviewing it. They are
  /// not built at all, so screen readers do not announce them either.
  final bool showMeaning;

  /// Non-null in selection mode: whether this word is selected.
  final bool? selected;

  /// Shown when words from several decks are listed together.
  final String? deckName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = this.selected;
    return Card(
      color: selected == true ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouch.minTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selected != null) ...[
                      Semantics(
                        checked: selected,
                        child: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          key: Key('entry.${entry.id}.select'),
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Expanded(
                      child: AutoDirectionText(
                        entry.original,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.wordTitle,
                      ),
                    ),
                    if (entry.isDifficult) ...[
                      const SizedBox(width: AppSpace.sm),
                      StatusBadge(
                        key: Key('entry.${entry.id}.difficult'),
                        label: l10n.entryDifficult,
                        tone: StatusTone.warning,
                        icon: Icons.flag,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                if (!showMeaning)
                  const SizedBox.shrink()
                else if (entry.hasMeanings)
                  AutoDirectionText(
                    entry.meanings.map((m) => m.text).join('، '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  )
                else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusBadge(
                      label: l10n.entryNoMeaning,
                      tone: StatusTone.neutral,
                    ),
                  ),
                if (deckName != null) ...[
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    l10n.entryInDeck(bidiIsolate(deckName!)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
