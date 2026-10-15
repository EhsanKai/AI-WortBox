import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/state_views.dart';
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
        title: Text(l10n.deleteEntryTitle(entry.original)),
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
        _ => const Center(child: CircularProgressIndicator()),
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

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        AutoDirectionText(
          entry.original,
          key: const Key('entryDetail.word'),
          style: theme.textTheme.headlineMedium,
        ),
        if (entry.grammarInfo != null || entry.partOfSpeech != null) ...[
          const SizedBox(height: 4),
          AutoDirectionText(
            [
              entry.partOfSpeech,
              entry.grammarInfo,
            ].whereType<String>().join(' · '),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (entry.lemma != null) ...[
          const SizedBox(height: 4),
          Text('${l10n.entryLemma}: ${entry.lemma}'),
        ],
        section(l10n.entryMeanings, [
          if (entry.meanings.isEmpty)
            Text(
              l10n.entryNoMeaning,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          for (final (index, meaning) in entry.meanings.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${index + 1}.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AutoDirectionText(
                          meaning.text,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (meaning.explanation != null)
                          AutoDirectionText(
                            meaning.explanation!,
                            style: theme.textTheme.bodyMedium,
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
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (entry.exampleSentence != null)
                      AutoDirectionText(
                        entry.exampleSentence!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    if (entry.exampleTranslation != null) ...[
                      const SizedBox(height: 6),
                      AutoDirectionText(
                        entry.exampleTranslation!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        if (entry.sourceContext != null)
          section(l10n.entrySource, [AutoDirectionText(entry.sourceContext!)]),
        if (entry.notes != null)
          section(l10n.entryNotes, [AutoDirectionText(entry.notes!)]),
        const SizedBox(height: 20),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.input),
          title: Text(l10n.entrySource),
          trailing: Text(switch (entry.sourceType) {
            VocabularySourceType.manual => l10n.sourceManual,
            VocabularySourceType.csv => l10n.sourceCsv,
            VocabularySourceType.image => l10n.sourceImage,
          }),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.entryStatus),
          trailing: Text(switch (entry.enrichmentStatus) {
            EnrichmentStatus.missing => l10n.entryStatusMissing,
            EnrichmentStatus.pending => l10n.entryStatusPending,
            EnrichmentStatus.ready => l10n.entryStatusReady,
            EnrichmentStatus.failed => l10n.entryStatusFailed,
          }),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.history),
          title: Text(l10n.entryUpdatedOn(entry.updatedAt.toLocal())),
        ),
      ],
    );
  }
}
