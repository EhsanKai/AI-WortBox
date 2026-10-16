import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/text/text_normalizer.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../../vocabulary/presentation/entry_tile.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../domain/deck.dart';
import 'deck_providers.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deck = ref.watch(deckProvider(deckId));

    return Scaffold(
      appBar: AppBar(
        title: switch (deck) {
          AsyncData(value: final d?) => AutoDirectionText(
            d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _ => const SizedBox.shrink(),
        },
        actions: [
          if (deck.value != null)
            IconButton(
              key: const Key('deck.scan'),
              tooltip: l10n.addScan,
              icon: const Icon(Icons.document_scanner_outlined),
              onPressed: () => context.push(AppRoutes.deckScan(deckId)),
            ),
          if (deck.value != null)
            IconButton(
              key: const Key('deck.importCsv'),
              tooltip: l10n.deckImportCsv,
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: () => context.push(AppRoutes.deckImport(deckId)),
            ),
        ],
      ),
      floatingActionButton: deck.value == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('deck.addWord'),
              onPressed: () => context.push(AppRoutes.newEntry(deckId)),
              icon: const Icon(Icons.add),
              label: Text(l10n.deckAddWord),
            ),
      body: switch (deck) {
        AsyncData(value: null) => EmptyStateView(
          icon: Icons.search_off,
          title: l10n.deckNotFound,
        ),
        AsyncData(value: final d?) => _DeckEntries(deck: d),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(deckProvider(deckId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DeckEntries extends ConsumerStatefulWidget {
  const _DeckEntries({required this.deck});

  final Deck deck;

  @override
  ConsumerState<_DeckEntries> createState() => _DeckEntriesState();
}

class _DeckEntriesState extends ConsumerState<_DeckEntries> {
  String _query = '';

  bool _matches(VocabularyEntry entry, String query) =>
      entry.normalized.contains(TextNormalizer.vocabularyKey(query)) ||
      entry.meanings.any(
        (m) =>
            TextNormalizer.meaningKey(m.text)
                .contains(TextNormalizer.meaningKey(query)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final deck = widget.deck;
    final entries = ref.watch(deckEntriesProvider(deck.id));

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        [
          l10n.deckLanguagePair(
            deck.sourceLanguage.nativeName,
            deck.definitionLanguage.nativeName,
          ),
          l10n.deckWordCount(entries.value?.length ?? 0),
          l10n.deckDailyLimit(deck.dailyNewCardLimit),
        ].join(' · '),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return switch (entries) {
      AsyncData(:final value) when value.isEmpty => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: EmptyStateView(
              icon: Icons.menu_book_outlined,
              title: l10n.deckNoEntriesTitle,
              message: l10n.deckNoEntriesBody,
            ),
          ),
        ],
      ),
      AsyncData(:final value) => _buildList(context, header, value),
      AsyncError(:final error) => ErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(deckEntriesProvider(deck.id)),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildList(
    BuildContext context,
    Widget header,
    List<VocabularyEntry> all,
  ) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim();
    final visible = query.isEmpty
        ? all
        : all.where((e) => _matches(e, query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchBar(
            key: const Key('deck.search'),
            hintText: l10n.searchHint,
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off,
                  title: l10n.searchNoResults,
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    return EntryTile(
                      entry: entry,
                      onTap: () =>
                          context.push(AppRoutes.entry(entry.deckId, entry.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
