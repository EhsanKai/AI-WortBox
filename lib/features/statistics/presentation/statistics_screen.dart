import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/study_statistics.dart';
import 'statistics_providers.dart';

/// Statistics from stored words and recorded practice reviews only.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(studyStatisticsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStatistics)),
      body: switch (stats) {
        AsyncData(:final value) => _Statistics(stats: value),
        AsyncError(:final error) => ErrorStateView(error: error),
        _ => const LoadingView(),
      },
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.stats});

  final StudyStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final percent = NumberFormat.percentPattern(l10n.localeName);
    final dayLabel = DateFormat.E(l10n.localeName);
    final maxReviews = stats.recentDays.fold(
      0,
      (max, d) => d.reviews > max ? d.reviews : max,
    );

    Widget tile(String key, String label, String value, IconData icon) => Card(
      key: Key('stats.$key'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpace.sm),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpace.md),
        Expanded(child: b),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        pair(
          tile(
            'words',
            l10n.statsWords,
            numbers.format(stats.totalWords),
            Icons.translate,
          ),
          tile(
            'difficult',
            l10n.statsDifficult,
            numbers.format(stats.difficultWords),
            Icons.flag_outlined,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (!stats.hasReviews) ...[
          EmptyStateView(
            key: const Key('stats.empty'),
            scrollable: false,
            icon: Icons.insights_outlined,
            title: l10n.statisticsEmpty,
            message: l10n.statsEmptyBody,
            action: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.practice),
              icon: const Icon(Icons.style_outlined),
              label: Text(l10n.practiceStart),
            ),
          ),
        ] else ...[
          pair(
            tile(
              'streak',
              l10n.statsCurrentStreak,
              l10n.statsDays(stats.currentStreak),
              Icons.local_fire_department_outlined,
            ),
            tile(
              'longest',
              l10n.statsLongestStreak,
              l10n.statsDays(stats.longestStreak),
              Icons.emoji_events_outlined,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          pair(
            tile(
              'reviews',
              l10n.statsReviews,
              numbers.format(stats.totalReviews),
              Icons.style_outlined,
            ),
            tile(
              'remembered',
              l10n.statsRemembered,
              percent.format(stats.rememberedReviews / stats.totalReviews),
              Icons.check_circle_outline,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          pair(
            tile(
              'sessions',
              l10n.statsSessions,
              numbers.format(stats.sessions),
              Icons.timer_outlined,
            ),
            tile(
              'days',
              l10n.statsStudyDays,
              numbers.format(stats.studyDays),
              Icons.calendar_month_outlined,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.statsRecentDays),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                children: [
                  for (final day in stats.recentDays.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xxs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(
                              dayLabel.format(
                                DateTime(
                                  day.day.year,
                                  day.day.month,
                                  day.day.day,
                                ),
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: maxReviews == 0
                                  ? 0
                                  : day.reviews / maxReviews,
                              minHeight: 8,
                              borderRadius: AppRadius.smAll,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              numbers.format(day.reviews),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        InfoBanner(icon: Icons.info_outline, message: l10n.statsPolicy),
      ],
    );
  }
}
