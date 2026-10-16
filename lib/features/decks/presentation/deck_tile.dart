import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/action_tile.dart';
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
    final colors = context.colors;
    final deck = summary.deck;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Container(
                width: AppTouch.minTarget,
                height: AppTouch.minTarget,
                decoration: BoxDecoration(
                  color: colors.box,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(Icons.inventory_2_outlined, color: colors.onBox),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AutoDirectionText(
                      deck.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      '${l10n.deckLanguagePair(deck.sourceLanguage.nativeName, deck.definitionLanguage.nativeName)}'
                      ' · ${l10n.deckWordCount(summary.entryCount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const DirectionalChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
