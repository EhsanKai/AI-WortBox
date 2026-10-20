import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/action_tile.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/domain/deck.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../decks/presentation/deck_tile.dart';
import '../../decks/presentation/decks_screen.dart';
import '../../review/presentation/memory_coach_providers.dart';
import '../../review/presentation/practice_screen.dart'
    show reviewDirectionLabel;
import '../../review/presentation/review_providers.dart';
import '../../statistics/presentation/statistics_providers.dart';

/// "Today": the dashboard, with the daily (FSRS) review first.
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
        _ => const LoadingView(),
      },
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.summaries});

  final List<DeckSummary> summaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final wordCount = summaries.fold<int>(0, (sum, s) => sum + s.entryCount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Row(
          children: [
            const BrandMark(size: 64),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    l10n.appTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        // First run: the call to action comes before anything else.
        if (summaries.isEmpty) ...[
          EmptyStateView(
            scrollable: false,
            icon: Icons.auto_stories_outlined,
            title: l10n.emptyDecksTitle,
            message: l10n.emptyDecksBody,
            action: FilledButton.icon(
              key: const Key('today.createDeck'),
              onPressed: () => createDeckAndAnnounce(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.actionCreateDeck),
            ),
          ),
        ] else ...[
          const _ReviewCard(),
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatCard(
                  key: const Key('today.deckCount'),
                  label: l10n.dashboardDecks,
                  value: numbers.format(summaries.length),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppSpace.md),
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
          const SizedBox(height: AppSpace.md),
          ActionTile(
            key: const Key('today.practice'),
            icon: Icons.style_outlined,
            title: l10n.practiceTitle,
            description: switch (ref
                .watch(studyStatisticsProvider)
                .value
                ?.currentStreak) {
              final streak? when streak > 0 => l10n.practiceTileStreak(streak),
              _ => l10n.practiceTileDescription,
            },
            onTap: () => context.go(AppRoutes.practice),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionTile(
            key: const Key('today.coach'),
            icon: Icons.psychology_alt_outlined,
            title: l10n.coachTitle,
            description: l10n.coachTileDescription(
              ref.watch(coachSuggestionsProvider).value?.length ?? 0,
            ),
            onTap: () => context.go(AppRoutes.memoryCoach),
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.dashboardYourDecks),
          for (final summary in summaries.take(5)) ...[
            DeckTile(
              summary: summary,
              onTap: () => context.go(AppRoutes.deck(summary.deck.id)),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ],
    );
  }
}

/// Cards due across all decks for the chosen direction, and the way in.
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final due = ref.watch(dueCountProvider(null)).value;
    final direction = ref.watch(reviewDirectionProvider).value;
    return Card(
      key: const Key('today.review'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_repeat, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    due == null ? l10n.reviewStart : l10n.reviewDueCount(due),
                    key: const Key('today.dueCount'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (direction != null) ...[
              const SizedBox(height: AppSpace.xxs),
              Text(
                reviewDirectionLabel(l10n, direction),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpace.md),
            FilledButton.icon(
              key: const Key('today.startReview'),
              onPressed: () => context.go(AppRoutes.practiceSession()),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.reviewStart),
            ),
          ],
        ),
      ),
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
    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpace.sm),
              Text(value, style: theme.textTheme.displaySmall),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
