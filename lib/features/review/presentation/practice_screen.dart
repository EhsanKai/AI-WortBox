import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../app/router.dart';
import '../../../core/design/app_colors.dart' show StatusTone;
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../speech/presentation/speak_button.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../domain/review_direction.dart';
import '../domain/review_event.dart';
import 'practice_controller.dart';
import 'review_providers.dart';

/// Chooses what to review: deck, direction and scheduled or free practice.
class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  ConsumerState<PracticeSetupScreen> createState() =>
      _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  String? _deckId;
  bool _difficultOnly = false;
  bool _free = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final decks = ref.watch(deckSummariesProvider).value ?? const [];
    final scheduled = !_free && !_difficultOnly;
    final due = ref.watch(dueCountProvider(_deckId)).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.practiceTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxl,
        ),
        children: [
          Text(l10n.practiceIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.reviewDirectionTitle),
          const ReviewDirectionPicker(),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.practiceWordsFrom),
          DropdownButtonFormField<String?>(
            key: const Key('practice.deck'),
            initialValue: _deckId,
            isExpanded: true,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.practiceAllDecks),
              ),
              for (final s in decks)
                DropdownMenuItem<String?>(
                  value: s.deck.id,
                  child: Text(
                    bidiIsolate(s.deck.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _deckId = value),
          ),
          const SizedBox(height: AppSpace.md),
          SwitchListTile(
            key: const Key('practice.free'),
            contentPadding: EdgeInsets.zero,
            value: !scheduled,
            title: Text(l10n.practiceFreeMode),
            secondary: const Icon(Icons.shuffle),
            onChanged: _difficultOnly
                ? null
                : (value) => setState(() => _free = value),
          ),
          SwitchListTile(
            key: const Key('practice.difficultOnly'),
            contentPadding: EdgeInsets.zero,
            value: _difficultOnly,
            title: Text(l10n.practiceDifficultOnly),
            secondary: const Icon(Icons.flag_outlined),
            onChanged: (value) => setState(() => _difficultOnly = value),
          ),
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            key: const Key('practice.modeNote'),
            icon: scheduled ? Icons.event_repeat : Icons.info_outline,
            message: scheduled
                ? l10n.practiceScheduledNote
                : l10n.practiceNotSrs,
          ),
          const SizedBox(height: AppSpace.xl),
          if (scheduled && due != null) ...[
            Text(
              l10n.reviewDueCount(due),
              key: const Key('practice.dueCount'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          FilledButton.icon(
            key: const Key('practice.start'),
            onPressed: () => context.push(
              AppRoutes.practiceSession(
                deckId: _deckId,
                difficultOnly: _difficultOnly,
                free: _free,
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: Text(scheduled ? l10n.reviewStart : l10n.practiceStart),
          ),
        ],
      ),
    );
  }
}

/// German → Persian, Persian → German or both; saved immediately.
class ReviewDirectionPicker extends ConsumerWidget {
  const ReviewDirectionPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = ref.watch(reviewDirectionProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<ReviewDirection>(
          groupValue: current,
          onChanged: (value) async {
            if (value == null) return;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(reviewDirectionProvider.notifier).set(value);
            } on Object catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text(errorMessage(l10n, e))),
              );
            }
          },
          child: Column(
            children: [
              for (final direction in ReviewDirection.values)
                RadioListTile<ReviewDirection>(
                  key: Key('reviewDirection.${direction.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: direction,
                  title: Text(reviewDirectionLabel(l10n, direction)),
                ),
            ],
          ),
        ),
        if (current == ReviewDirection.both)
          Text(
            l10n.reviewDirectionBothNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

String reviewDirectionLabel(AppLocalizations l10n, ReviewDirection d) =>
    switch (d) {
      ReviewDirection.germanToPersian => l10n.reviewDirectionGermanToPersian,
      ReviewDirection.persianToGerman => l10n.reviewDirectionPersianToGerman,
      ReviewDirection.both => l10n.reviewDirectionBoth,
    };

/// One session: prompt side → reveal → own outcome.
class PracticeSessionScreen extends ConsumerWidget {
  const PracticeSessionScreen({super.key, required this.config});

  final PracticeConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = practiceControllerProvider(config);
    final state = ref.watch(provider);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.phase == PracticePhase.question ||
                  state.phase == PracticePhase.answer
              ? l10n.practiceProgress(
                  numbers.format(state.index + 1),
                  numbers.format(state.cards.length),
                )
              : l10n.practiceTitle,
        ),
        leading: IconButton(
          key: const Key('practice.close'),
          tooltip: l10n.practiceEnd,
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: switch (state.phase) {
        PracticePhase.loading => const LoadingView(),
        PracticePhase.failed => ErrorStateView(
          error: state.error!,
          onRetry: () => ref.invalidate(provider),
        ),
        PracticePhase.empty when config.isScheduled => EmptyStateView(
          key: const Key('practice.nothingDue'),
          icon: Icons.event_available_outlined,
          title: l10n.practiceEmptyDueTitle,
          message: l10n.practiceEmptyDueBody,
          action: FilledButton.tonal(
            key: const Key('practice.freeInstead'),
            onPressed: () => context.pushReplacement(
              AppRoutes.practiceSession(deckId: config.deckId, free: true),
            ),
            child: Text(l10n.practiceFreeInstead),
          ),
        ),
        PracticePhase.empty => EmptyStateView(
          icon: Icons.style_outlined,
          title: l10n.practiceEmptyTitle,
          message: config.difficultOnly
              ? l10n.practiceEmptyDifficult
              : l10n.practiceEmptyBody,
          action: FilledButton(
            onPressed: () => context.pop(),
            child: Text(l10n.actionBack),
          ),
        ),
        PracticePhase.done => OutcomeView(
          key: const Key('practice.summary'),
          title: l10n.practiceDoneTitle,
          lines: [
            OutcomeLine(
              Icons.check_circle_outline,
              l10n.practiceRememberedCount(state.remembered),
              tone: StatusTone.success,
            ),
            OutcomeLine(
              Icons.replay,
              l10n.practiceForgottenCount(state.forgotten),
              tone: StatusTone.warning,
            ),
            if (config.isScheduled)
              OutcomeLine(Icons.event_repeat, l10n.practiceScheduledDone),
          ],
          primary: FilledButton(
            key: const Key('practice.finish'),
            onPressed: () => context.go(AppRoutes.today),
            child: Text(l10n.practiceFinish),
          ),
          secondary: OutlinedButton(
            onPressed: () => context.go(AppRoutes.statistics),
            child: Text(l10n.practiceSeeStatistics),
          ),
        ),
        PracticePhase.question || PracticePhase.answer => _Card(
          card: state.current!,
          revealed: state.phase == PracticePhase.answer,
          state: state,
          controller: ref.read(provider.notifier),
        ),
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.card,
    required this.revealed,
    required this.state,
    required this.controller,
  });

  final StudyCard card;
  final bool revealed;
  final PracticeState state;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entry = card.entry;

    return ListView(
      // A new card must never reuse the previous card's revealed widgets.
      key: ValueKey(('practice.card', state.index)),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        LinearProgressIndicator(
          value: state.cards.isEmpty ? 0 : state.index / state.cards.length,
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          card.asksMeaning ? l10n.practicePromptMeaning : l10n.practicePrompt,
          key: const Key('practice.promptLabel'),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpace.sm),
        Card(
          key: const Key('practice.prompt'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: card.asksMeaning
                ? _GermanSide(entry: entry, centered: true)
                : _MeaningSide(entry: entry, centered: true),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (!revealed)
          FilledButton.icon(
            key: const Key('practice.reveal'),
            onPressed: controller.reveal,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.practiceReveal),
          )
        else ...[
          Card(
            key: const Key('practice.answer'),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: card.asksMeaning
                  ? _MeaningSide(entry: entry, details: true)
                  : _GermanSide(entry: entry, details: true),
            ),
          ),
          if (state.error case final error?) ...[
            const SizedBox(height: AppSpace.md),
            InfoBanner(
              key: const Key('practice.error'),
              tone: StatusTone.danger,
              message: errorMessage(l10n, error),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text(l10n.practiceAsk, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('practice.forgotten'),
                  onPressed: state.isRecording
                      ? null
                      : () => controller.answer(ReviewOutcome.forgotten),
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.practiceForgotten),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('practice.remembered'),
                  onPressed: state.isRecording
                      ? null
                      : () => controller.answer(ReviewOutcome.remembered),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.practiceRemembered),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The German side: the word with pronunciation and, as an answer, its
/// base form, grammar and example.
class _GermanSide extends StatelessWidget {
  const _GermanSide({
    required this.entry,
    this.centered = false,
    this.details = false,
  });

  final VocabularyEntry entry;
  final bool centered;
  final bool details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AutoDirectionText(
                entry.original,
                key: const Key('practice.word'),
                textAlign: centered ? TextAlign.center : null,
                style: AppTypography.headword,
              ),
            ),
            SpeakButton(text: entry.original, language: entry.sourceLanguage),
          ],
        ),
        if (details) ...[
          if (entry.lemma != null)
            Text(
              '${l10n.entryLemma}: ${bidiIsolate(entry.lemma!)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          if (entry.grammarInfo != null)
            AutoDirectionText(
              entry.grammarInfo!,
              style: AppTypography.germanBody.copyWith(color: muted),
            ),
          if (entry.exampleSentence != null) ...[
            const SizedBox(height: AppSpace.sm),
            AutoDirectionText(
              entry.exampleSentence!,
              style: AppTypography.germanBody,
            ),
          ],
        ],
      ],
    );
  }
}

/// The Persian side: the meanings and, as an answer, the example's
/// translation.
class _MeaningSide extends StatelessWidget {
  const _MeaningSide({
    required this.entry,
    this.centered = false,
    this.details = false,
  });

  final VocabularyEntry entry;
  final bool centered;
  final bool details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final meaning in entry.meanings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: AutoDirectionText(
              meaning.text,
              key: const Key('practice.meaning'),
              textAlign: centered ? TextAlign.center : null,
              style: theme.textTheme.headlineSmall,
            ),
          ),
        if (details && entry.exampleTranslation != null) ...[
          const SizedBox(height: AppSpace.sm),
          AutoDirectionText(
            entry.exampleTranslation!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
