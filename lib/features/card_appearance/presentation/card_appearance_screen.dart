import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../domain/card_appearance.dart';
import 'card_style.dart';

/// Opens the appearance editor for [entryId] on top of the current screen
/// (also inside a review session; nothing is recorded there).
Future<void> openCardAppearance(BuildContext context, String entryId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CardAppearanceScreen(entryId: entryId),
      ),
    );

/// Edits how one word's card looks, with a live preview. Nothing is saved
/// until "Save"; "Cancel" discards the changes; "Reset" returns the draft
/// to the standard look (saved with "Save"). The word itself, its review
/// schedule and its history are never changed here.
class CardAppearanceScreen extends ConsumerStatefulWidget {
  const CardAppearanceScreen({super.key, required this.entryId});

  final String entryId;

  @override
  ConsumerState<CardAppearanceScreen> createState() =>
      _CardAppearanceScreenState();
}

class _CardAppearanceScreenState extends ConsumerState<CardAppearanceScreen> {
  CardAppearance? _saved;
  CardAppearance? _draft;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await ref
          .read(cardAppearanceRepositoryProvider)
          .get(widget.entryId);
      if (!mounted) return;
      setState(() => _saved = _draft = a);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  bool get _dirty => _draft != null && _draft != _saved;

  void _update(CardAppearance next) => setState(() => _draft = next);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(cardAppearanceRepositoryProvider)
          .save(widget.entryId, _draft!);
      _saved = _draft;
      messenger.showSnackBar(SnackBar(content: Text(l10n.appearanceSaved)));
      navigator.pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appearanceDiscardTitle),
        content: Text(l10n.appearanceDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.appearanceKeepEditing),
          ),
          FilledButton(
            key: const Key('appearance.discard'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.appearanceDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _cancel() async {
    final navigator = Navigator.of(context);
    if (await _confirmDiscard()) {
      _draft = _saved;
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = ref.watch(entryProvider(widget.entryId)).value;
    final draft = _draft;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _cancel();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.appearanceTitle)),
        body: switch ((entry, draft, _error)) {
          (_, _, final Object error) => ErrorStateView(error: error),
          (final VocabularyEntry e, final CardAppearance d, _) => _Editor(
            entry: e,
            draft: d,
            onChanged: _update,
          ),
          _ => const LoadingView(),
        },
        bottomNavigationBar: draft == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.sm,
                    AppSpace.gutter,
                    AppSpace.sm,
                  ),
                  // Stacks on narrow screens or with large text.
                  child: OverflowBar(
                    spacing: AppSpace.sm,
                    overflowSpacing: AppSpace.xs,
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [
                      TextButton(
                        key: const Key('appearance.reset'),
                        onPressed: draft.isStandard
                            ? null
                            : () => _update(CardAppearance.standard),
                        child: Text(l10n.appearanceReset),
                      ),
                      TextButton(
                        key: const Key('appearance.cancel'),
                        onPressed: _cancel,
                        child: Text(l10n.actionCancel),
                      ),
                      FilledButton(
                        key: const Key('appearance.save'),
                        onPressed: _saving || !_dirty ? null : _save,
                        child: _saving
                            ? const ButtonProgress()
                            : Text(l10n.appearanceSave),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.entry,
    required this.draft,
    required this.onChanged,
  });

  final VocabularyEntry entry;
  final CardAppearance draft;
  final ValueChanged<CardAppearance> onChanged;

  static final _token = RegExp(r'\S+');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final tokens = [for (final m in _token.allMatches(entry.original)) m[0]!];
    final meanings = [
      for (final m in entry.meanings)
        if (m.text.trim().isNotEmpty) m.text,
    ];

    Widget swatch({
      required Key key,
      required Color? color,
      required bool selected,
      required String label,
      required VoidCallback onTap,
      Widget? child,
    }) => Semantics(
      label: label,
      selected: selected,
      button: true,
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: AppTouch.minTarget,
          height: AppTouch.minTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? theme.colorScheme.surfaceContainerLow,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 3 : 1,
            ),
          ),
          child: child ?? (selected ? const Icon(Icons.check, size: 20) : null),
        ),
      ),
    );

    Widget sizeSlider(
      Key key,
      String label,
      double value,
      ValueChanged<double> onChanged,
    ) {
      final index = CardAppearance.scales.indexOf(value);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$label · ${(value * 100).round()}%',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            key: key,
            min: 0,
            max: (CardAppearance.scales.length - 1).toDouble(),
            divisions: CardAppearance.scales.length - 1,
            value: (index < 0 ? 1 : index).toDouble(),
            label: '${(value * 100).round()}%',
            onChanged: (v) => onChanged(CardAppearance.scales[v.round()]),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        SectionHeader(l10n.appearancePreview),
        KeyedSubtree(
          key: const Key('appearance.preview'),
          child: CardFacePreview(entry: entry, appearance: draft),
        ),
        const SizedBox(height: AppSpace.xl),
        SectionHeader(l10n.appearanceBackground),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final c in CardColor.values)
              swatch(
                key: Key('appearance.bg.${c.name}'),
                color: CardPalette.background(c, brightness),
                selected: draft.background == c,
                label: switch (c) {
                  CardColor.standard => l10n.appearanceStandard,
                  CardColor.sun => l10n.appearanceColorSun,
                  CardColor.mint => l10n.appearanceColorMint,
                  CardColor.sky => l10n.appearanceColorSky,
                  CardColor.rose => l10n.appearanceColorRose,
                  CardColor.lavender => l10n.appearanceColorLavender,
                  CardColor.sand => l10n.appearanceColorSand,
                },
                onTap: () => onChanged(draft.copyWith(background: c)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        SectionHeader(l10n.appearanceTextColor),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final c in CardInk.values)
              swatch(
                key: Key('appearance.ink.${c.name}'),
                color: CardPalette.ink(c, brightness),
                selected: draft.ink == c,
                label: switch (c) {
                  CardInk.standard => l10n.appearanceStandard,
                  CardInk.navy => l10n.appearanceInkNavy,
                  CardInk.green => l10n.appearanceInkGreen,
                  CardInk.plum => l10n.appearanceInkPlum,
                  CardInk.brown => l10n.appearanceInkBrown,
                },
                onTap: () => onChanged(draft.copyWith(ink: c)),
                child: draft.ink == c
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color: c == CardInk.standard
                            ? null
                            : theme.colorScheme.surface,
                      )
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        SectionHeader(l10n.appearanceTextSize),
        sizeSlider(
          const Key('appearance.wordSize'),
          l10n.appearanceWordSize,
          draft.wordScale,
          (v) => onChanged(draft.copyWith(wordScale: v)),
        ),
        sizeSlider(
          const Key('appearance.meaningSize'),
          l10n.appearanceMeaningSize,
          draft.meaningScale,
          (v) => onChanged(draft.copyWith(meaningScale: v)),
        ),
        const SizedBox(height: AppSpace.lg),
        SectionHeader(l10n.appearanceHighlight),
        Text(l10n.appearanceHighlightHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final c in HighlightColor.values)
              swatch(
                key: Key('appearance.hl.${c.name}'),
                color: CardPalette.highlight(c, brightness),
                selected: draft.highlightColor == c,
                label: switch (c) {
                  HighlightColor.yellow => l10n.appearanceMarkYellow,
                  HighlightColor.green => l10n.appearanceMarkGreen,
                  HighlightColor.pink => l10n.appearanceMarkPink,
                  HighlightColor.blue => l10n.appearanceMarkBlue,
                },
                onTap: () => onChanged(draft.copyWith(highlightColor: c)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final (i, t) in tokens.indexed)
              FilterChip(
                key: Key('appearance.token.$i'),
                label: Text(
                  t,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.germanBody,
                ),
                selected: draft.isHighlighted(HighlightField.word, t),
                onSelected: (_) =>
                    onChanged(draft.toggleHighlight(HighlightField.word, t)),
              ),
            for (final (i, m) in meanings.indexed)
              FilterChip(
                key: Key('appearance.meaning.$i'),
                label: Text(m, textDirection: TextDirection.rtl),
                selected: draft.isHighlighted(HighlightField.meaning, m),
                onSelected: (_) =>
                    onChanged(draft.toggleHighlight(HighlightField.meaning, m)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        SectionHeader(l10n.appearanceSticker),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            ChoiceChip(
              key: const Key('appearance.sticker.none'),
              label: Text(l10n.appearanceNoSticker),
              selected: draft.sticker == null,
              onSelected: (_) => onChanged(draft.copyWith(sticker: () => null)),
            ),
            for (final s in CardSticker.values)
              ChoiceChip(
                key: Key('appearance.sticker.${s.name}'),
                label: Text(s.emoji, style: const TextStyle(fontSize: 20)),
                selected: draft.sticker == s,
                onSelected: (_) => onChanged(draft.copyWith(sticker: () => s)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          l10n.appearanceNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Both faces of a card with [appearance]: the German word and the
/// meanings, as in review.
class CardFacePreview extends StatelessWidget {
  const CardFacePreview({
    super.key,
    required this.entry,
    required this.appearance,
  });

  final VocabularyEntry entry;
  final CardAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppearanceCardFrame(
          appearance: appearance,
          child: HighlightedText(
            entry.original,
            field: HighlightField.word,
            appearance: appearance,
            textAlign: TextAlign.center,
            style: cardTextStyle(
              context,
              entry.original.contains('\n')
                  ? AppTypography.headwordMultiline
                  : AppTypography.headword,
              appearance,
              appearance.wordScale,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        AppearanceCardFrame(
          appearance: appearance.copyWith(sticker: () => null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final m in entry.meanings)
                HighlightedText(
                  m.text,
                  field: HighlightField.meaning,
                  appearance: appearance,
                  textAlign: TextAlign.center,
                  style: cardTextStyle(
                    context,
                    theme.textTheme.headlineSmall,
                    appearance,
                    appearance.meaningScale,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
