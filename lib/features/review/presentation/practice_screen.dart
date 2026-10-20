import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/design/app_colors.dart' show StatusTone;
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../card_appearance/domain/card_appearance.dart';
import '../../card_appearance/presentation/card_appearance_screen.dart';
import '../../card_appearance/presentation/card_style.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../speech/presentation/speak_button.dart';
import '../../tags/presentation/entry_tags_sheet.dart';
import '../../tags/presentation/tag_providers.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../../vocabulary/presentation/vocabulary_form_screen.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
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
                  numbers.format(state.position),
                  numbers.format(state.total),
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
          message: config.coach
              ? l10n.practiceEmptyCoach
              : config.difficultOnly
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
            if (config.coach)
              OutcomeLine(Icons.event_available, l10n.coachPracticeNote),
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

class _Card extends ConsumerWidget {
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

  /// Opens the word's editor on top of the session. Nothing is recorded:
  /// the session, the card and its phase are unchanged when it closes, and
  /// the card shows the saved content (it watches the stored entry).
  Future<void> _edit(BuildContext context, VocabularyEntry entry) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VocabularyFormScreen(entryId: entry.id),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The stored entry, as on the word page, so an edit made from this card
    // shows at once; the session's copy is used while it loads (or if the
    // word was deleted meanwhile).
    final entry = ref.watch(entryProvider(card.entry.id)).value ?? card.entry;
    final appearance =
        ref.watch(cardAppearanceProvider(entry.id)).value ??
        CardAppearance.standard;

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
          value: state.total == 0 ? 0 : state.answeredCards / state.total,
        ),
        if (state.isRepeat) ...[
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusBadge(
              key: const Key('practice.repeat'),
              label: l10n.practiceRepeat,
              tone: StatusTone.accent,
              icon: Icons.replay,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        Text(
          card.asksMeaning ? l10n.practicePromptMeaning : l10n.practicePrompt,
          key: const Key('practice.promptLabel'),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpace.sm),
        AppearanceCardFrame(
          key: const Key('practice.prompt'),
          appearance: appearance,
          child: card.asksMeaning
              ? _GermanSide(
                  entry: entry,
                  appearance: appearance,
                  centered: true,
                )
              : _MeaningSide(
                  entry: entry,
                  appearance: appearance,
                  centered: true,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.sm,
                AppSpace.lg,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Text(
                      l10n.practiceAnswerDetails,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _AnswerActions(
                    entry: entry,
                    enabled: !state.isRecording,
                    onEdit: () => _edit(context, entry),
                  ),
                  card.asksMeaning
                      ? _MeaningSide(
                          entry: entry,
                          appearance: appearance,
                          explanations: true,
                        )
                      : _GermanSide(entry: entry, appearance: appearance),
                  _AnswerDetails(entry: entry),
                ],
              ),
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

/// Changes to the word that never record an answer or touch FSRS state:
/// edit its content, mark or unmark it as difficult, choose its tags.
class _AnswerActions extends ConsumerWidget {
  const _AnswerActions({
    required this.entry,
    required this.enabled,
    required this.onEdit,
  });

  final VocabularyEntry entry;
  final bool enabled;
  final VoidCallback onEdit;

  Future<void> _toggleDifficult(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(vocabularyRepositoryProvider)
          .setDifficult(entry.id, difficult: !entry.isDifficult);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tags = ref.watch(entryTagsProvider(entry.id)).value ?? const [];
    return Wrap(
      spacing: AppSpace.xs,
      children: [
        TextButton.icon(
          key: const Key('practice.edit'),
          onPressed: enabled ? onEdit : null,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.practiceEditWord),
        ),
        TextButton.icon(
          key: const Key('practice.difficult'),
          onPressed: enabled ? () => _toggleDifficult(context, ref) : null,
          icon: Icon(entry.isDifficult ? Icons.flag : Icons.flag_outlined),
          label: Text(
            entry.isDifficult
                ? l10n.entryUnmarkDifficult
                : l10n.entryMarkDifficult,
          ),
        ),
        TextButton.icon(
          key: const Key('practice.appearance'),
          onPressed: enabled
              ? () => openCardAppearance(context, entry.id)
              : null,
          icon: const Icon(Icons.palette_outlined),
          label: Text(l10n.appearanceAction),
        ),
        TextButton.icon(
          key: const Key('practice.tags.edit'),
          onPressed: enabled
              ? () => showEntryTagsSheet(
                  context,
                  entryId: entry.id,
                  selected: {for (final t in tags) t.id},
                )
              : null,
          icon: const Icon(Icons.label_outline),
          label: Text(tags.isEmpty ? l10n.tagsAdd : l10n.tagsEdit),
        ),
      ],
    );
  }
}

/// The German side: the word with pronunciation. Line breaks the user
/// entered are kept; long lines still wrap.
class _GermanSide extends StatelessWidget {
  const _GermanSide({
    required this.entry,
    required this.appearance,
    this.centered = false,
  });

  final VocabularyEntry entry;
  final CardAppearance appearance;
  final bool centered;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: HighlightedText(
          entry.original,
          key: const Key('practice.word'),
          field: HighlightField.word,
          appearance: appearance,
          textAlign: centered ? TextAlign.center : null,
          style: cardTextStyle(
            context,
            entry.original.contains('\n')
                ? AppTypography.headwordMultiline
                : AppTypography.headword,
            appearance,
            appearance.wordScale,
          ),
        ),
      ),
      SpeakButton(text: entry.original, language: entry.sourceLanguage),
    ],
  );
}

/// The Persian side: the meanings, as an answer with their explanations.
class _MeaningSide extends StatelessWidget {
  const _MeaningSide({
    required this.entry,
    required this.appearance,
    this.centered = false,
    this.explanations = false,
  });

  final VocabularyEntry entry;
  final CardAppearance appearance;
  final bool centered;
  final bool explanations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final meaning in entry.meanings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HighlightedText(
                  meaning.text,
                  key: const Key('practice.meaning'),
                  field: HighlightField.meaning,
                  appearance: appearance,
                  textAlign: centered ? TextAlign.center : null,
                  style: cardTextStyle(
                    context,
                    theme.textTheme.headlineSmall,
                    appearance,
                    appearance.meaningScale,
                  ),
                ),
                if (explanations && meaning.explanation != null)
                  AutoDirectionText(
                    meaning.explanation!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Everything else stored for the word, shown only after the reveal, in
/// both directions: grammar, base form, the example and its translation,
/// notes, the source sentence and tags. Empty fields are left out; nothing
/// is generated here.
class _AnswerDetails extends ConsumerWidget {
  const _AnswerDetails({required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final tags = ref.watch(entryTagsProvider(entry.id)).value ?? const [];
    final grammar = [
      entry.partOfSpeech,
      entry.grammarInfo,
    ].whereType<String>().join(' · ');

    Widget labelled(String label, Widget child, {Key? key}) => Padding(
      key: key,
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpace.xxs),
          child,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grammar.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: AutoDirectionText(
              grammar,
              key: const Key('practice.grammar'),
              style: AppTypography.germanBody.copyWith(color: muted),
            ),
          ),
        if (entry.lemma != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              '${l10n.entryLemma}: ${bidiIsolate(entry.lemma!)}',
              key: const Key('practice.lemma'),
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        if (entry.exampleSentence != null || entry.exampleTranslation != null)
          labelled(
            l10n.entryExample,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entry.exampleSentence case final example?)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AutoDirectionText(
                          example,
                          key: const Key('practice.example'),
                          style: AppTypography.germanBody,
                        ),
                      ),
                      SpeakButton(
                        text: example,
                        language: entry.sourceLanguage,
                        tooltip: l10n.speakExample,
                      ),
                    ],
                  ),
                if (entry.exampleTranslation case final translation?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: AutoDirectionText(
                      translation,
                      key: const Key('practice.exampleTranslation'),
                      style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
          ),
        if (entry.notes case final notes?)
          labelled(
            l10n.entryNotes,
            AutoDirectionText(
              notes,
              key: const Key('practice.notes'),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        if (entry.sourceContext case final source?)
          labelled(
            l10n.entrySource,
            AutoDirectionText(
              source,
              key: const Key('practice.source'),
              style: AppTypography.germanBody.copyWith(color: muted),
            ),
          ),
        if (tags.isNotEmpty)
          labelled(
            l10n.tagsTitle,
            Wrap(
              key: const Key('practice.tags'),
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final tag in tags)
                  Chip(
                    avatar: const Icon(Icons.label_outline, size: 18),
                    label: Text(bidiIsolate(tag.name)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
