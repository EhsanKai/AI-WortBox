import 'package:flutter/material.dart';

import '../../../core/widgets/auto_direction_text.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/vocabulary_entry.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.onTap});

  final VocabularyEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: AutoDirectionText(
        entry.original,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: entry.hasMeanings
          ? AutoDirectionText(
              entry.meanings.map((m) => m.text).join('، '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              l10n.entryNoMeaning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }
}
