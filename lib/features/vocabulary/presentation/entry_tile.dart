import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/vocabulary_entry.dart';

/// Vocabulary card in a deck list: the German word in the book face, its
/// Persian meanings below.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.onTap});

  final VocabularyEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
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
                AutoDirectionText(
                  entry.original,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.wordTitle,
                ),
                const SizedBox(height: AppSpace.xxs),
                if (entry.hasMeanings)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
