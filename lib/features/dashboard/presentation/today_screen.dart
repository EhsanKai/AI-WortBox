import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/domain/deck.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../decks/presentation/deck_tile.dart';
import '../../decks/presentation/decks_screen.dart';

/// "Today": the dashboard. Daily review is added in Phase 5.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summaries = ref.watch(deckSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navToday)),
      body: switch (summaries) {
        AsyncData(:final value) => _Dashboard(summaries: value),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(deckSummariesProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.summaries});

  final List<DeckSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final wordCount = summaries.fold<int>(0, (sum, s) => sum + s.entryCount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          l10n.appTagline,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                key: const Key('today.deckCount'),
                label: l10n.dashboardDecks,
                value: numbers.format(summaries.length),
                icon: Icons.style_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                key: const Key('today.wordCount'),
                label: l10n.dashboardWords,
                value: numbers.format(wordCount),
                icon: Icons.translate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card.filled(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.dashboardReviewPending),
          ),
        ),
        const SizedBox(height: 24),
        if (summaries.isEmpty)
          EmptyStateView(
            icon: Icons.auto_stories_outlined,
            title: l10n.emptyDecksTitle,
            message: l10n.emptyDecksBody,
            action: FilledButton.icon(
              key: const Key('today.createDeck'),
              onPressed: () => createDeckAndAnnounce(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.actionCreateDeck),
            ),
          )
        else ...[
          Text(l10n.dashboardYourDecks, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final summary in summaries.take(5)) ...[
            DeckTile(
              summary: summary,
              onTap: () => context.go(AppRoutes.deck(summary.deck.id)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
