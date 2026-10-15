import 'package:flutter/material.dart';

import '../../../core/widgets/auto_direction_text.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/deck.dart';

class DeckTile extends StatelessWidget {
  const DeckTile({super.key, required this.summary, this.onTap});

  final DeckSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final deck = summary.deck;
    return Card.outlined(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.style_outlined),
        ),
        title: AutoDirectionText(
          deck.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          '${l10n.deckLanguagePair(deck.sourceLanguage.nativeName, deck.definitionLanguage.nativeName)}'
          ' · ${l10n.deckWordCount(summary.entryCount)}',
        ),
        trailing: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left
              : Icons.chevron_right,
        ),
      ),
    );
  }
}
