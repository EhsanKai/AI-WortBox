import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/tokens.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/domain/deck.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../tags/domain/tag.dart';
import '../../tags/presentation/tag_providers.dart';
import '../domain/vocabulary_entry.dart';
import '../domain/vocabulary_search.dart';
import 'entry_tile.dart';
import 'vocabulary_providers.dart';

/// Search field, tag and "difficult" filters, and the matching words.
///
/// With [deckId] it browses one deck (and shows the full deck list while no
/// filter is active); without, it searches every deck and shows each word's
/// deck. Matching runs in the database (see `VocabularySearch`).
///
/// Long-pressing a word starts selection mode: taps then select or
/// deselect words, and the toolbar selects all, clears the selection or
/// deletes the selected words after confirmation.
class VocabularyBrowser extends ConsumerStatefulWidget {
  const VocabularyBrowser({
    super.key,
    this.deckId,
    this.header,
    this.emptyDeck,
    this.showMeanings = true,
  });

  final String? deckId;

  /// False lists only the German words (see `EntryTile.showMeaning`).
  final bool showMeanings;

  /// Shown above the search field.
  final Widget? header;

  /// Shown instead of the list when the deck has no words at all.
  final Widget? emptyDeck;

  @override
  ConsumerState<VocabularyBrowser> createState() => _VocabularyBrowserState();
}

class _VocabularyBrowserState extends ConsumerState<VocabularyBrowser> {
  late VocabularyQuery _query = VocabularyQuery(deckId: widget.deckId);
  final _text = TextEditingController();

  /// Non-null while in selection mode.
  Set<String>? _selected;
  bool _deleting = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  // A changed query changes which words are listed, so a selection made
  // for the previous list is dropped.
  void _update(VocabularyQuery query) => setState(() {
    _query = query;
    if (_selected != null) _selected = {};
  });

  void _toggle(String id) => setState(() {
    final selected = {...?_selected};
    if (!selected.remove(id)) selected.add(id);
    _selected = selected;
  });

  void _exitSelection() => setState(() => _selected = null);

  Future<void> _deleteSelected(List<VocabularyEntry> listed) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ids = [
      for (final e in listed)
        if (_selected?.contains(e.id) ?? false) e.id,
    ];
    if (ids.isEmpty || _deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bulkDeleteTitle(ids.length)),
        content: Text(l10n.bulkDeleteBody),
        actions: [
          TextButton(
            key: const Key('browser.deleteCancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('browser.deleteConfirm'),
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
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    String message;
    try {
      final deleted = await ref
          .read(vocabularyRepositoryProvider)
          .deleteEntries(ids);
      message = l10n.bulkDeleted(deleted);
      if (mounted) setState(() => _selected = null);
    } on Object catch (e) {
      message = errorMessage(l10n, e);
    }
    if (mounted) setState(() => _deleting = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _selectionBar(List<VocabularyEntry> listed) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selected ?? const <String>{};
    final count = listed.where((e) => selected.contains(e.id)).length;
    return Material(
      key: const Key('browser.selectionBar'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
        child: Row(
          children: [
            IconButton(
              key: const Key('browser.exitSelection'),
              tooltip: l10n.selectionExit,
              icon: const Icon(Icons.close),
              onPressed: _exitSelection,
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.selectionCount(count),
                  key: const Key('browser.selectedCount'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('browser.selectAll'),
              tooltip: l10n.selectionSelectAll,
              icon: const Icon(Icons.select_all),
              onPressed: listed.isEmpty
                  ? null
                  : () => setState(
                      () => _selected = {for (final e in listed) e.id},
                    ),
            ),
            IconButton(
              key: const Key('browser.clearSelection'),
              tooltip: l10n.selectionClear,
              icon: const Icon(Icons.deselect),
              onPressed: count == 0
                  ? null
                  : () => setState(() => _selected = {}),
            ),
            IconButton(
              key: const Key('browser.deleteSelected'),
              tooltip: l10n.selectionDelete,
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              onPressed: count == 0 || _deleting
                  ? null
                  : () => _deleteSelected(listed),
            ),
          ],
        ),
      ),
    );
  }

  void _clear() {
    _text.clear();
    _update(VocabularyQuery(deckId: widget.deckId));
  }

  Future<void> _pickTag(List<Tag> tags) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              key: const Key('browser.tag.any'),
              leading: const Icon(Icons.label_off_outlined),
              title: Text(l10n.filterAllTags),
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final tag in tags)
              ListTile(
                key: Key('browser.tag.${tag.id}'),
                leading: const Icon(Icons.label_outline),
                title: Text(bidiIsolate(tag.name)),
                trailing: Text(l10n.tagWordCount(tag.entryCount)),
                selected: tag.id == _query.tagId,
                onTap: () => Navigator.pop(context, tag.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    _update(_query.copyWith(tagId: () => picked.isEmpty ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final selectedTag = tags.where((t) => t.id == _query.tagId).firstOrNull;

    final AsyncValue<List<VocabularyEntry>> results =
        widget.deckId != null && !_query.isFiltered
        ? ref.watch(deckEntriesProvider(widget.deckId!))
        : ref.watch(vocabularySearchProvider(_query));
    final deckNames = widget.deckId == null
        ? {
            for (final s
                in ref.watch(deckSummariesProvider).value ??
                    const <DeckSummary>[])
              s.deck.id: s.deck.name,
          }
        : const <String, String>{};

    final deckIsEmpty =
        widget.emptyDeck != null &&
        !_query.isFiltered &&
        results.value?.isEmpty == true;
    if (deckIsEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?widget.header,
          Expanded(child: widget.emptyDeck!),
        ],
      );
    }

    final listed = results.value ?? const <VocabularyEntry>[];
    final selecting = _selected != null;
    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selecting) _selectionBar(listed) else ?widget.header,
          if (selecting) const SizedBox(height: AppSpace.sm),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.sm,
            ),
            child: TextField(
              key: Key(
                widget.deckId == null ? 'browser.search' : 'deck.search',
              ),
              controller: _text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('browser.clearText'),
                        tooltip: l10n.searchClear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _text.clear();
                          _update(_query.copyWith(text: ''));
                        },
                      ),
              ),
              onChanged: (value) => _update(_query.copyWith(text: value)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.sm,
            ),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('browser.difficult'),
                  avatar: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(l10n.filterDifficult),
                  selected: _query.difficultOnly,
                  onSelected: (value) =>
                      _update(_query.copyWith(difficultOnly: value)),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(width: AppSpace.sm),
                  FilterChip(
                    key: const Key('browser.tag'),
                    avatar: const Icon(Icons.label_outline, size: 18),
                    label: Text(
                      selectedTag == null
                          ? l10n.filterTag
                          : bidiIsolate(selectedTag.name),
                    ),
                    selected: selectedTag != null,
                    onSelected: (_) => _pickTag(tags),
                  ),
                ],
                if (_query.isFiltered) ...[
                  const SizedBox(width: AppSpace.sm),
                  ActionChip(
                    key: const Key('browser.clearAll'),
                    avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: Text(l10n.filterClear),
                    onPressed: _clear,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: switch (results) {
              AsyncData(:final value) when value.isEmpty => EmptyStateView(
                icon: Icons.search_off,
                title: l10n.searchNoResults,
                action: _query.isFiltered
                    ? TextButton(
                        onPressed: _clear,
                        child: Text(l10n.filterClear),
                      )
                    : null,
              ),
              AsyncData(:final value) => ListView.separated(
                key: const Key('browser.results'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  0,
                  AppSpace.gutter,
                  AppSpace.fabClearance,
                ),
                itemCount:
                    value.length +
                    (value.length >= AppConfig.maxSearchResults ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                itemBuilder: (context, index) {
                  if (index == value.length) {
                    return Text(
                      l10n.searchLimited(AppConfig.maxSearchResults),
                      textAlign: TextAlign.center,
                    );
                  }
                  final entry = value[index];
                  final selected = _selected?.contains(entry.id);
                  return EntryTile(
                    key: Key('browser.entry.${entry.id}'),
                    entry: entry,
                    deckName: deckNames[entry.deckId],
                    showMeaning: widget.showMeanings,
                    selected: selected,
                    onTap: selected != null
                        ? () => _toggle(entry.id)
                        : () => context.push(
                            AppRoutes.entry(entry.deckId, entry.id),
                          ),
                    onLongPress: () => selected == null
                        ? setState(() => _selected = {entry.id})
                        : _toggle(entry.id),
                  );
                },
              ),
              AsyncError(:final error) => ErrorStateView(error: error),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}
