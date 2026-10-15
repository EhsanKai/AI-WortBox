import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import 'deck_providers.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final deck = ref.watch(deckProvider(deckId));

    return Scaffold(
      appBar: AppBar(
        title: switch (deck) {
          AsyncData(value: final d?) => AutoDirectionText(
            d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
      body: switch (deck) {
        AsyncData(value: null) => EmptyStateView(
          icon: Icons.search_off,
          title: l10n.deckNotFound,
        ),
        AsyncData(value: final d?) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card.filled(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(
                      l10n.deckLanguagePair(
                        d.sourceLanguage.nativeName,
                        d.definitionLanguage.nativeName,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.fiber_new_outlined),
                    title: Text(l10n.deckDailyLimit(d.dailyNewCardLimit)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(l10n.deckCreatedOn(d.createdAt.toLocal())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.deckEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(deckProvider(deckId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
