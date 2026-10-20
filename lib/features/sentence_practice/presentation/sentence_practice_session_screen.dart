import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../speech/presentation/speak_button.dart';
import '../domain/sentence_exercise.dart';
import '../domain/sentence_practice.dart';
import 'sentence_practice_controller.dart';

/// One sentence-practice session.
class SentencePracticeSessionScreen extends ConsumerStatefulWidget {
  const SentencePracticeSessionScreen({super.key, required this.config});

  final SentenceSessionConfig config;

  @override
  ConsumerState<SentencePracticeSessionScreen> createState() =>
      _SentencePracticeSessionScreenState();
}

class _SentencePracticeSessionScreenState
    extends ConsumerState<SentencePracticeSessionScreen> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = sentencePracticeControllerProvider(widget.config);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    // A new exercise starts with an empty answer field; a failed check
    // keeps the typed answer.
    ref.listen(provider.select((s) => s.index), (_, _) => _answer.clear());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.spTitle)),
      body: switch (state.phase) {
        SentencePhase.generating => LoadingView(message: l10n.spGenerating),
        SentencePhase.noWords => EmptyStateView(
          key: const Key('sp.noWords'),
          icon: Icons.translate,
          title: l10n.spNoWordsTitle,
          message: l10n.spNoWordsBody,
        ),
        SentencePhase.generationFailed => _GenerationFailed(
          error: state.error!,
          onRetry: controller.retryGeneration,
        ),
        SentencePhase.done => _Summary(state: state),
        _ => _ExerciseView(
          config: widget.config,
          state: state,
          answer: _answer,
          controller: controller,
        ),
      },
    );
  }
}

class _GenerationFailed extends StatelessWidget {
  const _GenerationFailed({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notConfigured =
        error is EnrichmentException &&
        (error as EnrichmentException).error == EnrichmentError.notConfigured;
    final attempts = error is EnrichmentException
        ? (error as EnrichmentException).attempts
        : const <AiAttempt>[];
    final theme = Theme.of(context);
    return ListView(
      key: const Key('sp.generationFailed'),
      children: [
        EmptyStateView(
          scrollable: false,
          icon: Icons.cloud_off_outlined,
          tone: StatusTone.danger,
          title: l10n.spGenerationFailedTitle,
          message:
              '${errorMessage(l10n, error)}\n\n${l10n.spGenerationFailedHint}',
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                key: const Key('sp.retryGeneration'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
              if (notConfigured) ...[
                const SizedBox(height: AppSpace.sm),
                TextButton(
                  onPressed: () => context.go(AppRoutes.aiSettings),
                  child: Text(l10n.spOpenAiSettings),
                ),
              ],
            ],
          ),
        ),
        if (attempts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: Card(
              child: ExpansionTile(
                key: const Key('sp.technicalDetails'),
                shape: const Border(),
                title: Text(l10n.spTechnicalDetails),
                subtitle: Text(l10n.spTechnicalNote),
                children: [
                  for (final (i, a) in attempts.indexed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        0,
                        AppSpace.lg,
                        AppSpace.sm,
                      ),
                      child: SelectableText(
                        '${i + 1}. $a',
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  if ((error as EnrichmentException).detail case final d?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        0,
                        AppSpace.lg,
                        AppSpace.lg,
                      ),
                      child: SelectableText(
                        d,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExerciseView extends StatelessWidget {
  const _ExerciseView({
    required this.config,
    required this.state,
    required this.answer,
    required this.controller,
  });

  final SentenceSessionConfig config;
  final SentenceSessionState state;
  final TextEditingController answer;
  final SentencePracticeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exercise = state.current!;
    final direction = config.direction;
    final produce = direction == SentencePracticeDirection.produce;
    final checking = state.phase == SentencePhase.checking;
    final reviewed = state.phase == SentencePhase.reviewed;
    final total = state.exercises.length;
    final prompt = exercise.promptFor(direction);
    final isLast = state.index + 1 >= total;

    return ListView(
      key: ValueKey('sp.exercise.${state.index}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Text(
          l10n.spProgress(state.index + 1, total),
          key: const Key('sp.progress'),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpace.xs),
        LinearProgressIndicator(value: (state.index + 1) / total),
        if (state.rejected > 0 && state.index == 0) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            key: const Key('sp.rejected'),
            message: l10n.spRejected(state.rejected),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  produce
                      ? l10n.spInstructionProduce
                      : l10n.spInstructionUnderstand,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AutoDirectionText(
                        prompt,
                        key: const Key('sp.prompt'),
                        style: produce
                            ? theme.textTheme.titleLarge
                            : AppTypography.germanBody.copyWith(
                                fontSize: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                      ),
                    ),
                    if (!produce) SpeakButton(text: prompt),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.spTargetWord, style: theme.textTheme.labelLarge),
                    Chip(
                      key: const Key('sp.targetWord'),
                      label: Text(
                        exercise.word.original,
                        textDirection: TextDirection.ltr,
                        style: AppTypography.germanBody,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          key: const Key('sp.answer'),
          controller: answer,
          enabled: !checking && !reviewed,
          minLines: 2,
          maxLines: 5,
          maxLength: AppConfig.sentenceAnswerMaxLength,
          textDirection: produce ? TextDirection.ltr : TextDirection.rtl,
          style: produce ? AppTypography.germanBody : null,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: produce
                ? l10n.spAnswerLabelGerman
                : l10n.spAnswerLabelPersian,
          ),
          onChanged: controller.updateAnswer,
        ),
        if (state.error != null && !reviewed) ...[
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            key: const Key('sp.checkError'),
            tone: StatusTone.danger,
            title: errorMessage(l10n, state.error!),
            message: l10n.spCheckFailedKept,
          ),
        ],
        const SizedBox(height: AppSpace.md),
        if (!reviewed) ...[
          FilledButton.icon(
            key: const Key('sp.check'),
            onPressed: checking || state.answer.trim().isEmpty
                ? null
                : controller.submit,
            icon: checking
                ? const ButtonProgress()
                : const Icon(Icons.fact_check_outlined),
            label: Text(l10n.spCheck),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  key: const Key('sp.reveal'),
                  onPressed: checking ? null : controller.reveal,
                  child: Text(l10n.spShowAnswer),
                ),
              ),
              Expanded(
                child: TextButton(
                  key: const Key('sp.skip'),
                  onPressed: checking ? null : controller.next,
                  child: Text(l10n.spSkip),
                ),
              ),
            ],
          ),
        ] else ...[
          if (state.feedback case final feedback?) ...[
            _FeedbackCard(feedback: feedback, produce: produce),
            const SizedBox(height: AppSpace.md),
          ],
          _ModelAnswer(text: exercise.answerFor(direction), german: produce),
          const SizedBox(height: AppSpace.lg),
          FilledButton.icon(
            key: const Key('sp.next'),
            onPressed: controller.next,
            icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
            label: Text(isLast ? l10n.spFinish : l10n.spNext),
          ),
        ],
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback, required this.produce});

  final SentenceFeedback feedback;
  final bool produce;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (label, tone) = switch (feedback.verdict) {
      SentenceVerdict.correct => (l10n.spVerdictCorrect, StatusTone.success),
      SentenceVerdict.acceptable => (
        l10n.spVerdictAcceptable,
        StatusTone.success,
      ),
      SentenceVerdict.minorErrors => (l10n.spVerdictMinor, StatusTone.warning),
      SentenceVerdict.incorrect => (l10n.spVerdictIncorrect, StatusTone.danger),
    };
    TextStyle? answerStyle(TextStyle? base) =>
        produce ? AppTypography.germanBody : base;
    return Card(
      key: const Key('sp.feedback'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                key: const Key('sp.verdict'),
                label: label,
                tone: tone,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              switch (feedback.targetWord) {
                TargetWordUse.correct => l10n.spTargetCorrect,
                TargetWordUse.incorrect => l10n.spTargetIncorrect,
                TargetWordUse.missing => l10n.spTargetMissing,
              },
              key: const Key('sp.targetUse'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpace.sm),
            AutoDirectionText(
              feedback.explanation,
              key: const Key('sp.explanation'),
              style: theme.textTheme.bodyMedium,
            ),
            if (feedback.corrections.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Text(l10n.spCorrectionsTitle, style: theme.textTheme.titleSmall),
              for (final c in feedback.corrections)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kindLabel(l10n, c.kind),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${c.original}  →  ${c.corrected}',
                        textDirection: AutoDirectionText.directionOf(
                          c.corrected,
                        ),
                        style: answerStyle(theme.textTheme.bodyMedium),
                      ),
                      if (c.explanation case final e?)
                        AutoDirectionText(e, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
            if (feedback.correctedAnswer case final corrected?) ...[
              const SizedBox(height: AppSpace.md),
              Text(l10n.spCorrectedAnswer, style: theme.textTheme.titleSmall),
              AutoDirectionText(
                corrected,
                key: const Key('sp.correctedAnswer'),
                style: answerStyle(theme.textTheme.bodyMedium),
              ),
            ],
            if (feedback.naturalVersion case final natural?) ...[
              const SizedBox(height: AppSpace.md),
              Text(l10n.spNaturalVersion, style: theme.textTheme.titleSmall),
              AutoDirectionText(
                natural,
                key: const Key('sp.naturalVersion'),
                style: answerStyle(theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _kindLabel(AppLocalizations l10n, CorrectionKind kind) =>
      switch (kind) {
        CorrectionKind.grammar => l10n.spKindGrammar,
        CorrectionKind.wordOrder => l10n.spKindWordOrder,
        CorrectionKind.spelling => l10n.spKindSpelling,
        CorrectionKind.capitalization => l10n.spKindCapitalization,
        CorrectionKind.vocabulary => l10n.spKindVocabulary,
        CorrectionKind.meaning => l10n.spKindMeaning,
      };
}

class _ModelAnswer extends StatelessWidget {
  const _ModelAnswer({required this.text, required this.german});

  final String text;
  final bool german;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const Key('sp.modelAnswer'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.spModelAnswer, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Expanded(
                  child: AutoDirectionText(
                    text,
                    key: const Key('sp.modelAnswerText'),
                    style: german
                        ? AppTypography.germanBody
                        : theme.textTheme.bodyLarge,
                  ),
                ),
                if (german) SpeakButton(text: text),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.spModelAnswerNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final SentenceSessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    int count(Set<SentencePracticeOutcome> kinds) =>
        state.outcomes.where(kinds.contains).length;
    final good = count({
      SentencePracticeOutcome.correct,
      SentencePracticeOutcome.acceptable,
    });
    final minor = count({SentencePracticeOutcome.minorErrors});
    final wrong = count({SentencePracticeOutcome.incorrect});
    final unchecked = count({
      SentencePracticeOutcome.revealed,
      SentencePracticeOutcome.skipped,
    });
    return OutcomeView(
      key: const Key('sp.summary'),
      title: l10n.spDoneTitle,
      lines: [
        OutcomeLine(
          Icons.check_circle_outline,
          l10n.spDoneCorrect(good),
          tone: StatusTone.success,
        ),
        if (minor > 0)
          OutcomeLine(
            Icons.edit_note,
            l10n.spDoneMinor(minor),
            tone: StatusTone.warning,
          ),
        if (wrong > 0)
          OutcomeLine(
            Icons.close,
            l10n.spDoneIncorrect(wrong),
            tone: StatusTone.danger,
          ),
        if (unchecked > 0)
          OutcomeLine(
            Icons.visibility_outlined,
            l10n.spDoneUnchecked(unchecked),
          ),
        OutcomeLine(Icons.event_repeat, l10n.spDoneFsrsNote),
      ],
      primary: FilledButton(
        key: const Key('sp.again'),
        onPressed: () => context.pop(),
        child: Text(l10n.spPracticeAgain),
      ),
      secondary: TextButton(
        key: const Key('sp.backToToday'),
        onPressed: () => context.go(AppRoutes.today),
        child: Text(l10n.spBackToToday),
      ),
    );
  }
}
