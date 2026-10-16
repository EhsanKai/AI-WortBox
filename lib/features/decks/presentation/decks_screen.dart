import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import 'create_deck_sheet.dart';
import 'deck_providers.dart';
import 'deck_tile.dart';

/// "My Words": the list of the user's decks.
class DecksScreen extends ConsumerWidget {
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summaries = ref.watch(deckSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMyWords)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('decks.create'),
        onPressed: () => createDeckAndAnnounce(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.actionCreateDeck),
      ),
      body: switch (summaries) {
        AsyncData(:final value) when value.isEmpty => EmptyStateView(
          icon: Icons.inventory_2_outlined,
          title: l10n.emptyDecksTitle,
          message: l10n.emptyDecksBody,
        ),
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.sm,
            AppSpace.gutter,
            AppSpace.fabClearance,
          ),
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
          itemBuilder: (context, index) {
            final summary = value[index];
            return DeckTile(
              summary: summary,
              onTap: () => context.go(AppRoutes.deck(summary.deck.id)),
            );
          },
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(deckSummariesProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

/// Opens the create-deck sheet and confirms success with a snackbar.
Future<void> createDeckAndAnnounce(BuildContext context) async {
  final deck = await showCreateDeckSheet(context);
  if (deck == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(context).deckCreatedMessage(bidiIsolate(deck.name)),
      ),
    ),
  );
}
