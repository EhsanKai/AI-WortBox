import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../decks/presentation/decks_screen.dart';
import '../../vocabulary/domain/duplicate_detection.dart';
import '../domain/scan_review_item.dart';
import 'scan_controller.dart';

/// Lists exactly what will be saved, lets the user correct each item and
/// choose the deck and duplicate handling.
class ScanReviewView extends ConsumerWidget {
  const ScanReviewView({super.key, required this.initialDeckId});

  final String? initialDeckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = scanControllerProvider(initialDeckId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final decks = ref.watch(deckSummariesProvider);
    final decisions = ref.watch(scanDecisionsProvider(initialDeckId)).value;

    final deckList = decks.value ?? const [];
    if (decks.hasValue && deckList.isEmpty) {
      return EmptyStateView(
        icon: Icons.style_outlined,
        title: l10n.formNoDecks,
        action: FilledButton.icon(
          onPressed: () => createDeckAndAnnounce(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.actionCreateDeck),
        ),
      );
    }
    final deckId = state.deckId;
    if (deckList.isNotEmpty && !deckList.any((s) => s.deck.id == deckId)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.selectDeck(deckList.first.deck.id),
      );
    }

    final saveCount =
        decisions?.values
            .where(
              (d) =>
                  d is CreateDecision ||
                  d is MergeIntoEntryDecision ||
                  d is MergeIntoRowDecision,
            )
            .length ??
        0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(l10n.scanReviewIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          l10n.scanOcrWarning,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (deckList.isNotEmpty)
          DropdownButtonFormField<String>(
            key: const Key('scan.deck'),
            initialValue: deckList.any((s) => s.deck.id == deckId)
                ? deckId
                : deckList.first.deck.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.formDeckLabel),
            items: [
              for (final s in deckList)
                DropdownMenuItem(
                  value: s.deck.id,
                  child: AutoDirectionText(s.deck.name, maxLines: 1),
                ),
            ],
            onChanged: state.isBusy
                ? null
                : (id) {
                    if (id != null) controller.selectDeck(id);
                  },
          ),
        const SizedBox(height: 8),
        for (final (index, (_, item)) in state.items.indexed)
          _ReviewItemCard(
            key: ValueKey(item.id),
            item: item,
            decision: decisions?[index + 1],
            onChanged: controller.updateItem,
            onRemove: () => controller.removeItem(item.id),
          ),
        const SizedBox(height: 8),
        Text(l10n.csvSectionDuplicates, style: theme.textTheme.titleSmall),
        RadioGroup<DuplicateStrategy>(
          groupValue: state.strategy,
          onChanged: (v) => controller.setStrategy(v ?? state.strategy),
          child: Column(
            children: [
              for (final (value, title) in [
                (DuplicateStrategy.skip, l10n.csvStrategySkip),
                (DuplicateStrategy.mergeMeanings, l10n.csvStrategyMerge),
                (DuplicateStrategy.keepSeparate, l10n.csvStrategySeparate),
              ])
                RadioListTile<DuplicateStrategy>(
                  key: Key('scan.strategy.${value.name}'),
                  contentPadding: EdgeInsets.zero,
                  value: value,
                  title: Text(title),
                ),
            ],
          ),
        ),
        Text(
          l10n.csvStrategyNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.saveError != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.scanSaveFailed,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('scan.save'),
          onPressed: saveCount == 0 || state.isBusy ? null : controller.save,
          child: state.isBusy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.scanSaveButton(saveCount)),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('scan.backToText'),
          onPressed: controller.backToSelect,
          child: Text(l10n.scanBackToText),
        ),
      ],
    );
  }
}

class _ReviewItemCard extends StatefulWidget {
  const _ReviewItemCard({
    super.key,
    required this.item,
    required this.decision,
    required this.onChanged,
    required this.onRemove,
  });

  final ScanReviewItem item;
  final ImportDecision? decision;
  final ValueChanged<ScanReviewItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ReviewItemCard> createState() => _ReviewItemCardState();
}

class _ReviewItemCardState extends State<_ReviewItemCard> {
  late final _word = TextEditingController(text: widget.item.original);
  late final _context = TextEditingController(text: widget.item.context);
  late final _lemma = TextEditingController(text: widget.item.lemma);
  late final _meaning = TextEditingController(text: widget.item.meaning);

  @override
  void dispose() {
    for (final c in [_word, _context, _lemma, _meaning]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() => widget.onChanged(
    widget.item.copyWith(
      original: _word.text,
      context: _context.text,
      lemma: _lemma.text,
      meaning: _meaning.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = widget.item.id;
    final hint = widget.item.hint;

    final (status, color) = switch (widget.decision) {
      null => (l10n.scanStatusInvalid, theme.colorScheme.error),
      CreateDecision() => (l10n.scanStatusNew, theme.colorScheme.primary),
      MergeIntoEntryDecision() || MergeIntoRowDecision() => (
        l10n.scanStatusMerge,
        theme.colorScheme.tertiary,
      ),
      SkipDecision(reason: SkipReason.redundant, :final targetRowNumber?) => (
        l10n.scanStatusRedundantInList,
        theme.colorScheme.outline,
      ),
      SkipDecision(reason: SkipReason.redundant) => (
        l10n.scanStatusRedundant,
        theme.colorScheme.outline,
      ),
      SkipDecision() => (l10n.scanStatusExists, theme.colorScheme.outline),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card.outlined(
        key: Key('scan.item.$id'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status,
                      key: Key('scan.item.$id.status'),
                      style: theme.textTheme.labelLarge?.copyWith(color: color),
                    ),
                  ),
                  IconButton(
                    key: Key('scan.item.$id.remove'),
                    tooltip: l10n.scanItemRemove,
                    icon: const Icon(Icons.close),
                    onPressed: widget.onRemove,
                  ),
                ],
              ),
              TextField(
                key: Key('scan.item.$id.word'),
                controller: _word,
                textDirection: TextDirection.ltr,
                maxLength: AppConfig.maxOriginalLength,
                decoration: InputDecoration(
                  labelText: l10n.scanItemWord,
                  counterText: '',
                ),
                onChanged: (_) => _emit(),
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Card.filled(
                  key: Key('scan.item.$id.hint'),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(l10n.scanLemmaHint(hint.baseForm)),
                    subtitle: Text(l10n.scanLemmaHintNote),
                    trailing: TextButton(
                      key: Key('scan.item.$id.useHint'),
                      onPressed: () {
                        _lemma.text = hint.baseForm;
                        _emit();
                      },
                      child: Text(l10n.scanUseHint),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                key: Key('scan.item.$id.lemma'),
                controller: _lemma,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l10n.scanItemLemma),
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 8),
              TextField(
                key: Key('scan.item.$id.meaning'),
                controller: _meaning,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(labelText: l10n.scanItemMeaning),
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 8),
              TextField(
                key: Key('scan.item.$id.context'),
                controller: _context,
                textDirection: TextDirection.ltr,
                minLines: 1,
                maxLines: 4,
                maxLength: AppConfig.maxTextFieldLength,
                decoration: InputDecoration(
                  labelText: l10n.scanItemContext,
                  counterText: '',
                ),
                onChanged: (_) => _emit(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
