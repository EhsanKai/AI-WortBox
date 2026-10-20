import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
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
        icon: Icons.inventory_2_outlined,
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
    final toSave = [
      for (final (index, (_, item)) in state.items.indexed)
        if (decisions?[index + 1]
            case CreateDecision() ||
                MergeIntoEntryDecision() ||
                MergeIntoRowDecision())
          item.original.trim(),
    ];
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final failed = [
      for (final id in state.photoSelectionIds)
        if (state.failedStrokes.contains(id))
          numbers.format(state.selectionNumber(id)),
    ];
    final fromPhoto = state.document == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Text(l10n.scanReviewIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpace.md),
        InfoBanner(tone: StatusTone.warning, message: l10n.scanOcrWarning),
        if (failed.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            key: const Key('scan.failedHighlights'),
            tone: StatusTone.danger,
            icon: Icons.error_outline,
            message: l10n.scanFailedHighlights(failed.join('، ')),
            action: TextButton(
              key: const Key('scan.redraw'),
              onPressed: controller.backToSelect,
              child: Text(l10n.scanBackToPhoto),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
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
        const SizedBox(height: AppSpace.lg),
        for (final (index, (_, item)) in state.items.indexed)
          _ReviewItemCard(
            key: ValueKey(item.id),
            item: item,
            decision: decisions?[index + 1],
            onChanged: controller.updateItem,
            onRemove: () => controller.removeItem(item.id),
            onSplit: item.original.trim().contains(RegExp(r'\s'))
                ? () => controller.splitItem(item.id)
                : null,
            onCombineNext: index + 1 < state.items.length
                ? () => controller.combineWithNext(item.id)
                : null,
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('scan.addItem'),
            onPressed: controller.addItem,
            icon: const Icon(Icons.add),
            label: Text(l10n.scanAddWord),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SectionHeader(l10n.csvSectionDuplicates),
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
          const SizedBox(height: AppSpace.lg),
          InfoBanner(tone: StatusTone.danger, message: l10n.scanSaveFailed),
        ],
        const SizedBox(height: AppSpace.xl),
        Card(
          key: const Key('scan.summary'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.scanSummaryTitle(toSave.length),
                  style: theme.textTheme.titleSmall,
                ),
                if (toSave.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    toSave.join(' · '),
                    key: const Key('scan.summaryWords'),
                    textDirection: TextDirection.ltr,
                    style: AppTypography.germanBody,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        FilledButton(
          key: const Key('scan.save'),
          onPressed: saveCount == 0 || state.isBusy ? null : controller.save,
          child: state.isBusy
              ? const ButtonProgress()
              : Text(l10n.scanSaveButton(saveCount)),
        ),
        const SizedBox(height: AppSpace.sm),
        TextButton(
          key: const Key('scan.backToText'),
          onPressed: controller.backToSelect,
          child: Text(fromPhoto ? l10n.scanBackToPhoto : l10n.scanBackToText),
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
    this.onSplit,
    this.onCombineNext,
  });

  final ScanReviewItem item;
  final ImportDecision? decision;
  final ValueChanged<ScanReviewItem> onChanged;
  final VoidCallback onRemove;

  /// Null when the item is a single word.
  final VoidCallback? onSplit;

  /// Null for the last item.
  final VoidCallback? onCombineNext;

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
    final id = widget.item.id;
    final hint = widget.item.hint;

    final (status, tone) = switch (widget.decision) {
      null => (l10n.scanStatusInvalid, StatusTone.danger),
      CreateDecision() => (l10n.scanStatusNew, StatusTone.success),
      MergeIntoEntryDecision() ||
      MergeIntoRowDecision() => (l10n.scanStatusMerge, StatusTone.warning),
      SkipDecision(reason: SkipReason.redundant, :final targetRowNumber?) => (
        l10n.scanStatusRedundantInList,
        StatusTone.neutral,
      ),
      SkipDecision(reason: SkipReason.redundant) => (
        l10n.scanStatusRedundant,
        StatusTone.neutral,
      ),
      SkipDecision() => (l10n.scanStatusExists, StatusTone.neutral),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Card(
        key: Key('scan.item.$id'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xs,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StatusBadge(
                        label: status,
                        tone: tone,
                        textKey: Key('scan.item.$id.status'),
                      ),
                    ),
                  ),
                  if (widget.onSplit != null)
                    IconButton(
                      key: Key('scan.item.$id.split'),
                      tooltip: l10n.scanSplitItem,
                      icon: const Icon(Icons.call_split),
                      onPressed: widget.onSplit,
                    ),
                  if (widget.onCombineNext != null)
                    IconButton(
                      key: Key('scan.item.$id.combine'),
                      tooltip: l10n.scanCombineNext,
                      icon: const Icon(Icons.merge),
                      onPressed: widget.onCombineNext,
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
                style: AppTypography.wordTitle,
                maxLength: AppConfig.maxOriginalLength,
                decoration: InputDecoration(
                  labelText: l10n.scanItemWord,
                  counterText: '',
                ),
                onChanged: (_) => _emit(),
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpace.sm),
                InfoBanner(
                  key: Key('scan.item.$id.hint'),
                  tone: StatusTone.accent,
                  title: l10n.scanLemmaHint(hint.baseForm),
                  message: l10n.scanLemmaHintNote,
                  action: TextButton(
                    key: Key('scan.item.$id.useHint'),
                    onPressed: () {
                      _lemma.text = hint.baseForm;
                      _emit();
                    },
                    child: Text(l10n.scanUseHint),
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              TextField(
                key: Key('scan.item.$id.lemma'),
                controller: _lemma,
                textDirection: TextDirection.ltr,
                style: AppTypography.germanBody,
                decoration: InputDecoration(labelText: l10n.scanItemLemma),
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                key: Key('scan.item.$id.meaning'),
                controller: _meaning,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(labelText: l10n.scanItemMeaning),
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                key: Key('scan.item.$id.context'),
                controller: _context,
                textDirection: TextDirection.ltr,
                style: AppTypography.germanBody,
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
