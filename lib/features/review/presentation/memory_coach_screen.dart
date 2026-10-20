import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/app_colors.dart' show StatusTone;
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import 'memory_coach_providers.dart';

/// The Memory Coach: words the learner keeps failing to remember (see
/// `MemoryCoachRule`) and a focused practice of them.
///
/// Opening or browsing this screen only reads review history; focused
/// practice is free practice and never changes FSRS scheduling.
class MemoryCoachScreen extends ConsumerWidget {
  const MemoryCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final suggestions = ref.watch(coachSuggestionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachTitle)),
      body: switch (suggestions) {
        AsyncData(:final value) when value.isEmpty => EmptyStateView(
          key: const Key('coach.empty'),
          icon: Icons.psychology_alt_outlined,
          title: l10n.coachEmptyTitle,
          message: l10n.coachEmptyBody,
          action: FilledButton.tonal(
            key: const Key('coach.goToReview'),
            onPressed: () => context.go(AppRoutes.practice),
            child: Text(l10n.coachGoToReview),
          ),
        ),
        AsyncData(:final value) => _CoachList(suggestions: value),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(coachSuggestionsProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _CoachList extends ConsumerWidget {
  const _CoachList({required this.suggestions});

  final List<CoachSuggestion> suggestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rule = ref.watch(memoryCoachRuleProvider);
    final practicable = suggestions.any((s) => s.entry.hasMeanings);
    return ListView(
      key: const Key('coach.list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Text(
          l10n.coachIntro(
            rule.lookback.inDays,
            rule.minFailedSessions,
            rule.window,
            rule.recoveryStreak,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        InfoBanner(
          key: const Key('coach.note'),
          icon: Icons.event_available,
          message: l10n.coachPracticeNote,
        ),
        const SizedBox(height: AppSpace.md),
        FilledButton.icon(
          key: const Key('coach.start'),
          onPressed: practicable
              ? () => context.push(AppRoutes.practiceSession(coach: true))
              : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.coachStart),
        ),
        const SizedBox(height: AppSpace.lg),
        for (final suggestion in suggestions) ...[
          _CoachTile(suggestion: suggestion),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

/// One suggested word: word, meaning, the evidence and its example or note.
/// Tapping opens the word page; nothing is recorded.
class _CoachTile extends ConsumerWidget {
  const _CoachTile({required this.suggestion});

  final CoachSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    // The stored entry, so edits made from the word page show here.
    final entry =
        ref.watch(entryProvider(suggestion.entry.id)).value ?? suggestion.entry;
    final evidence = suggestion.evidence;
    final extra = entry.exampleSentence ?? entry.notes;
    return Card(
      key: Key('coach.word.${entry.id}'),
      child: InkWell(
        onTap: () => context.push(AppRoutes.entry(entry.deckId, entry.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutoDirectionText(entry.original, style: AppTypography.wordTitle),
              if (entry.hasMeanings)
                AutoDirectionText(
                  entry.meanings.map((m) => m.text).join('، '),
                  style: theme.textTheme.bodyLarge,
                ),
              const SizedBox(height: AppSpace.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(
                  key: Key('coach.failures.${entry.id}'),
                  label: l10n.coachFailures(
                    evidence.failures,
                    evidence.attempts,
                  ),
                  tone: StatusTone.warning,
                  icon: Icons.replay,
                ),
              ),
              if (extra != null) ...[
                const SizedBox(height: AppSpace.xs),
                AutoDirectionText(
                  extra,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.germanBody.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
