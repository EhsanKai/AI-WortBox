import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../export/presentation/deck_exporter.dart';
import '../../review/presentation/review_providers.dart';
import '../../vocabulary/presentation/vocabulary_browser.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../domain/deck.dart';
import 'deck_providers.dart';

/// A deck's words. Meanings are hidden until the learner asks to see them,
/// so opening a deck does not give away the answers; reviewing happens one
/// card at a time after "Start review".
class DeckDetailScreen extends ConsumerStatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  bool _showMeanings = false;

  String get deckId => widget.deckId;

  @override
  Widget build(BuildContext context) {
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
              key: const Key('deck.toggleMeanings'),
              tooltip: _showMeanings
                  ? l10n.deckHideMeanings
                  : l10n.deckShowMeanings,
              isSelected: _showMeanings,
              icon: const Icon(Icons.visibility_off_outlined),
              selectedIcon: const Icon(Icons.visibility_outlined),
              onPressed: () => setState(() => _showMeanings = !_showMeanings),
            ),
          if (deck.value != null)
            IconButton(
              key: const Key('deck.enrich'),
              tooltip: l10n.enrichDeckAction,
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: () => context.push(AppRoutes.deckEnrich(deckId)),
            ),
          if (deck.value != null)
            IconButton(
              key: const Key('deck.scan'),
              tooltip: l10n.addScan,
              icon: const Icon(Icons.document_scanner_outlined),
              onPressed: () => context.push(AppRoutes.deckScan(deckId)),
            ),
          if (deck.value case final d?)
            PopupMenuButton<String>(
              key: const Key('deck.menu'),
              tooltip: l10n.deckMoreActions,
              onSelected: (action) => switch (action) {
                'import' => context.push(AppRoutes.deckImport(deckId)),
                'csv' => _export(context, ref, d, ExportFormat.csv),
                'anki' => _export(context, ref, d, ExportFormat.ankiPackage),
                _ => null,
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  key: const Key('deck.importCsv'),
                  value: 'import',
                  child: ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(l10n.deckImportFile),
                  ),
                ),
                PopupMenuItem(
                  key: const Key('deck.exportCsv'),
                  value: 'csv',
                  child: ListTile(
                    leading: const Icon(Icons.table_view_outlined),
                    title: Text(l10n.exportCsv),
                  ),
                ),
                PopupMenuItem(
                  key: const Key('deck.exportAnki'),
                  value: 'anki',
                  child: ListTile(
                    leading: const Icon(Icons.style_outlined),
                    title: Text(l10n.exportAnki),
                  ),
                ),
              ],
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
        AsyncData(value: final d?) => _DeckEntries(
          deck: d,
          showMeanings: _showMeanings,
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(deckProvider(deckId)),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _DeckEntries extends ConsumerWidget {
  const _DeckEntries({required this.deck, required this.showMeanings});

  final Deck deck;
  final bool showMeanings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = ref.watch(deckEntriesProvider(deck.id)).value?.length ?? 0;

    final due = ref.watch(dueCountProvider(deck.id)).value;
    return VocabularyBrowser(
      deckId: deck.id,
      showMeanings: showMeanings,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xs,
          AppSpace.gutter,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                l10n.deckLanguagePair(
                  deck.sourceLanguage.nativeName,
                  deck.definitionLanguage.nativeName,
                ),
                l10n.deckWordCount(count),
                l10n.deckDailyLimit(deck.dailyNewCardLimit),
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('deck.startReview'),
                      onPressed: () => context.push(
                        AppRoutes.practiceSession(deckId: deck.id),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        due == null
                            ? l10n.reviewStart
                            : '${l10n.reviewStart} · ${l10n.reviewDueShort(due)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  IconButton.outlined(
                    key: const Key('deck.freePractice'),
                    tooltip: l10n.practiceFreeInstead,
                    icon: const Icon(Icons.shuffle),
                    onPressed: () => context.push(
                      AppRoutes.practiceSession(deckId: deck.id, free: true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      emptyDeck: EmptyStateView(
        icon: Icons.menu_book_outlined,
        title: l10n.deckNoEntriesTitle,
        message: l10n.deckNoEntriesBody,
      ),
    );
  }
}

/// Exports [deck] in [format] through the platform save dialog and reports
/// the outcome.
Future<void> _export(
  BuildContext context,
  WidgetRef ref,
  Deck deck,
  ExportFormat format,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  String message;
  try {
    final saved = await ref.read(deckExporterProvider).export(deck, format);
    message = saved ? l10n.exportSaved : l10n.exportCancelled;
  } on AppException catch (e) {
    message = errorMessage(l10n, e);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
