import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/ai_model_catalog.dart';
import '../domain/enrichment_plan.dart';
import 'ai_settings_controller.dart';
import 'enrichment_controller.dart';

/// Request AI suggestions for one entry or a deck's entries without
/// meanings, review them, and save the chosen parts.
class EnrichmentScreen extends ConsumerWidget {
  const EnrichmentScreen({super.key, required this.deckId, this.entryId});

  final String deckId;
  final String? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final target = (deckId: deckId, entryId: entryId);
    final state = ref.watch(enrichmentControllerProvider(target));
    final controller = ref.read(enrichmentControllerProvider(target).notifier);
    final running = state.phase == EnrichmentPhase.running;

    return PopScope(
      // Leaving stops a running batch; nothing unsaved is written.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) controller.cancel();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.enrichTitle)),
        body: switch (state.phase) {
          EnrichmentPhase.notConfigured => EmptyStateView(
            icon: Icons.key_outlined,
            title: l10n.enrichNotConfiguredTitle,
            message: l10n.enrichNotConfiguredBody,
            action: FilledButton.icon(
              key: const Key('enrich.openSettings'),
              onPressed: () async {
                await context.push(AppRoutes.aiSettings);
                await controller.reload();
              },
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.enrichOpenSettings),
            ),
          ),
          EnrichmentPhase.empty => EmptyStateView(
            icon: Icons.check_circle_outline,
            title: l10n.enrichEmptyTitle,
            message: l10n.enrichEmptyBody,
          ),
          EnrichmentPhase.done => OutcomeView(
            key: const Key('enrich.done'),
            title: l10n.enrichSavedTitle,
            lines: [
              OutcomeLine(
                Icons.auto_awesome_outlined,
                l10n.enrichSavedCount(state.savedCount),
                tone: StatusTone.success,
              ),
              if (state.costUsd case final cost?)
                OutcomeLine(
                  Icons.receipt_long_outlined,
                  l10n.enrichCost(_money(l10n).format(cost)),
                ),
            ],
            primary: FilledButton(
              key: const Key('enrich.viewDeck'),
              onPressed: () => context.go(
                entryId == null
                    ? AppRoutes.deck(deckId)
                    : AppRoutes.entry(deckId, entryId!),
              ),
              child: Text(l10n.csvViewDeck),
            ),
          ),
          _ when state.items.isEmpty => const LoadingView(),
          _ => _SessionView(
            state: state,
            controller: controller,
            single: entryId != null,
            running: running,
          ),
        },
      ),
    );
  }
}

intl.NumberFormat _money(AppLocalizations l10n) =>
    intl.NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 4,
    );

class _SessionView extends ConsumerWidget {
  const _SessionView({
    required this.state,
    required this.controller,
    required this.single,
    required this.running,
  });

  final EnrichmentState state;
  final EnrichmentController controller;
  final bool single;
  final bool running;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final model = ref.watch(aiSettingsControllerProvider).value?.model;
    final phase = state.phase;
    final total = state.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.sm,
              AppSpace.gutter,
              AppSpace.lg,
            ),
            children: [
              if (phase == EnrichmentPhase.ready) ...[
                InfoBanner(
                  key: const Key('enrich.privacy'),
                  icon: Icons.public,
                  message: single
                      ? l10n.enrichReadySingle
                      : l10n.enrichReadyBatch(total),
                ),
                if (model != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    l10n.enrichModel(
                      AiModelCatalog.byId(model)?.label ?? model,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpace.lg),
              ],
              if (running) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.enrichProgress(state.doneCount, total),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                LinearProgressIndicator(
                  value: total == 0 ? null : state.doneCount / total,
                ),
                const SizedBox(height: AppSpace.lg),
              ],
              if (state.stopError case final error?) ...[
                InfoBanner(
                  key: const Key('enrich.stopError'),
                  tone: StatusTone.danger,
                  message: errorMessage(l10n, error),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
              if (state.saveError case final error?) ...[
                InfoBanner(
                  key: const Key('enrich.saveError'),
                  tone: StatusTone.danger,
                  message: errorMessage(l10n, error),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
              for (final (index, item) in state.items.indexed)
                _ItemCard(
                  key: ValueKey(item.entry.id),
                  index: index,
                  item: item,
                  controller: controller,
                  editable: phase == EnrichmentPhase.review,
                ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (phase) {
                  EnrichmentPhase.ready => [
                    FilledButton.icon(
                      key: const Key('enrich.start'),
                      onPressed: controller.start,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text(l10n.enrichStart),
                    ),
                  ],
                  EnrichmentPhase.running => [
                    OutlinedButton.icon(
                      key: const Key('enrich.cancel'),
                      onPressed: controller.cancel,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(l10n.enrichCancel),
                    ),
                  ],
                  _ => [
                    FilledButton(
                      key: const Key('enrich.save'),
                      onPressed:
                          state.selectedCount == 0 ||
                              phase == EnrichmentPhase.saving
                          ? null
                          : controller.save,
                      child: phase == EnrichmentPhase.saving
                          ? const ButtonProgress()
                          : Text(l10n.enrichSave(state.selectedCount)),
                    ),
                    if (state.hasFailures &&
                        state.stopError == null &&
                        phase == EnrichmentPhase.review) ...[
                      const SizedBox(height: AppSpace.sm),
                      OutlinedButton(
                        key: const Key('enrich.retry'),
                        onPressed: controller.retry,
                        child: Text(l10n.enrichRetry),
                      ),
                    ],
                  ],
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.controller,
    required this.editable,
  });

  final int index;
  final EnrichmentItem item;
  final EnrichmentController controller;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = item.plan;
    final id = item.entry.id;

    final (label, tone) = switch (item.status) {
      ItemStatus.queued => (l10n.enrichStatusQueued, StatusTone.neutral),
      ItemStatus.running => (l10n.enrichStatusRunning, StatusTone.accent),
      ItemStatus.proposed => (l10n.enrichStatusProposed, StatusTone.accent),
      ItemStatus.failed => (l10n.enrichStatusFailed, StatusTone.danger),
      ItemStatus.skipped => (l10n.enrichStatusSkipped, StatusTone.neutral),
    };

    String fieldLabel(EnrichmentField field) => switch (field) {
      EnrichmentField.lemma => l10n.entryLemma,
      EnrichmentField.partOfSpeech => l10n.entryPartOfSpeech,
      EnrichmentField.grammarInfo => l10n.entryGrammar,
      EnrichmentField.example => l10n.entryExample,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Card(
        key: Key('enrich.item.$id'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutoDirectionText(
                item.entry.original,
                style: AppTypography.wordTitle,
              ),
              if (item.entry.meanings.isNotEmpty)
                AutoDirectionText(
                  item.entry.meanings.map((m) => m.text).join('، '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge(
                  label: label,
                  tone: tone,
                  icon: item.status == ItemStatus.proposed
                      ? Icons.auto_awesome_outlined
                      : null,
                  textKey: Key('enrich.item.$id.status'),
                ),
              ),
              if (item.error case final error?) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  errorMessage(l10n, error),
                  key: Key('enrich.item.$id.error'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.danger.foreground,
                  ),
                ),
              ],
              if (plan != null && item.status == ItemStatus.proposed) ...[
                if (plan.proposal.isAmbiguous) ...[
                  const SizedBox(height: AppSpace.sm),
                  InfoBanner(
                    tone: StatusTone.warning,
                    message: l10n.enrichAmbiguous,
                  ),
                ],
                if (plan.newMeanings.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(
                    l10n.enrichNewMeanings,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (item.entry.hasMeanings)
                    Text(
                      l10n.enrichExistingKept,
                      style: theme.textTheme.bodySmall,
                    ),
                  for (final (m, meaning) in plan.newMeanings.indexed)
                    CheckboxListTile(
                      key: Key('enrich.item.$id.meaning.$m'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: item.meanings.contains(m),
                      onChanged: editable
                          ? (_) => controller.toggleMeaning(index, m)
                          : null,
                      title: AutoDirectionText(meaning.text),
                      subtitle: meaning.explanation == null
                          ? null
                          : AutoDirectionText(meaning.explanation!),
                    ),
                ],
                if (plan.fields.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(l10n.enrichDetails, style: theme.textTheme.titleSmall),
                  for (final field in plan.fields)
                    CheckboxListTile(
                      key: Key('enrich.item.$id.field.${field.field.name}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: item.fields.contains(field.field),
                      onChanged: editable
                          ? (_) => controller.toggleField(index, field.field)
                          : null,
                      title: Text(fieldLabel(field.field)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AutoDirectionText(
                            field.proposed,
                            style: AppTypography.germanBody.copyWith(
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (field.proposedTranslation case final t?)
                            AutoDirectionText(t),
                          if (field.current case final current?)
                            Text(
                              l10n.enrichReplaces(bidiIsolate(current)),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.warning.foreground,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
