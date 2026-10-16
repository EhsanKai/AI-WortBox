import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/vocabulary_entry.dart';
import 'vocabulary_providers.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({
    super.key,
    required this.deckId,
    required this.entryId,
  });

  final String deckId;
  final String entryId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    VocabularyEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.deleteEntryTitle(bidiIsolate(entry.original))),
        content: Text(l10n.deleteEntryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('entryDetail.confirmDelete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(vocabularyRepositoryProvider).deleteEntry(entry.id);
      messenger.showSnackBar(SnackBar(content: Text(l10n.entryDeletedMessage)));
      if (context.mounted) context.go(AppRoutes.deck(deckId));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entry = ref.watch(entryProvider(entryId));
    final current = entry.value;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (current != null) ...[
            IconButton(
              key: const Key('entryDetail.edit'),
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push(AppRoutes.editEntry(deckId, entryId)),
            ),
            IconButton(
              key: const Key('entryDetail.delete'),
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, current),
            ),
          ],
        ],
      ),
      body: switch (entry) {
        AsyncData(value: final e?) => _EntryDetails(entry: e),
        AsyncData() => EmptyStateView(
          icon: Icons.search_off,
          title: l10n.entryNotFound,
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(entryProvider(entryId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _EntryDetails extends StatelessWidget {
  const _EntryDetails({required this.entry});

  final VocabularyEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SectionHeader(title), ...children],
      ),
    );

    final grammar = [
      entry.partOfSpeech,
      entry.grammarInfo,
    ].whereType<String>().join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        // The headword card.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg + AppSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutoDirectionText(
                  entry.original,
                  key: const Key('entryDetail.word'),
                  style: AppTypography.headword,
                ),
                if (grammar.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  AutoDirectionText(
                    grammar,
                    style: AppTypography.germanBody.copyWith(color: muted),
                  ),
                ],
                if (entry.lemma != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '${l10n.entryLemma}: ${bidiIsolate(entry.lemma!)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        section(l10n.entryMeanings, [
          if (entry.meanings.isEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                label: l10n.entryNoMeaning,
                tone: StatusTone.neutral,
              ),
            ),
          for (final (index, meaning) in entry.meanings.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: AppSpace.xxs),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.highlight,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      NumberFormat.decimalPattern(l10n.localeName)
                          .format(index + 1),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onHighlight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AutoDirectionText(
                          meaning.text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        if (meaning.explanation != null)
                          AutoDirectionText(
                            meaning.explanation!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ]),
        if (entry.exampleSentence != null || entry.exampleTranslation != null)
          section(l10n.entryExample, [
            _QuoteBlock(
              children: [
                if (entry.exampleSentence != null)
                  AutoDirectionText(
                    entry.exampleSentence!,
                    style: AppTypography.germanBody,
                  ),
                if (entry.exampleTranslation != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  AutoDirectionText(
                    entry.exampleTranslation!,
                    style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ]),
        if (entry.sourceContext != null)
          section(l10n.entrySource, [
            _QuoteBlock(
              children: [
                AutoDirectionText(
                  entry.sourceContext!,
                  style: AppTypography.germanBody,
                ),
              ],
            ),
          ]),
        if (entry.notes != null)
          section(l10n.entryNotes, [
            AutoDirectionText(entry.notes!, style: theme.textTheme.bodyLarge),
          ]),
        const SizedBox(height: AppSpace.xl),
        Card(
          child: Column(
            children: [
              _MetaRow(
                icon: Icons.input,
                label: l10n.entrySource,
                value: Text(switch (entry.sourceType) {
                  VocabularySourceType.manual => l10n.sourceManual,
                  VocabularySourceType.csv => l10n.sourceCsv,
                  VocabularySourceType.image => l10n.sourceImage,
                }),
              ),
              const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
              _MetaRow(
                icon: Icons.auto_awesome_outlined,
                label: l10n.entryStatus,
                value: StatusBadge(
                  label: switch (entry.enrichmentStatus) {
                    EnrichmentStatus.missing => l10n.entryStatusMissing,
                    EnrichmentStatus.pending => l10n.entryStatusPending,
                    EnrichmentStatus.ready => l10n.entryStatusReady,
                    EnrichmentStatus.failed => l10n.entryStatusFailed,
                  },
                  tone: switch (entry.enrichmentStatus) {
                    EnrichmentStatus.missing => StatusTone.neutral,
                    EnrichmentStatus.pending => StatusTone.accent,
                    EnrichmentStatus.ready => StatusTone.success,
                    EnrichmentStatus.failed => StatusTone.danger,
                  },
                ),
              ),
              const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
              _MetaRow(
                icon: Icons.history,
                label: l10n.entryUpdatedOn(entry.updatedAt.toLocal()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A label with an optional value; wraps instead of overflowing when the
/// text is large.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final Widget? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge),
                  if (value != null)
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: value!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quotation from a text: an example sentence or the page it came from.
class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: ColoredBox(
        color: colors.paper,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: colors.box, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
