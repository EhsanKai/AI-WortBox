import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/image_fit.dart';
import '../domain/scan_document.dart';
import '../domain/text_tokenizer.dart';
import '../domain/word_selection.dart';
import 'scan_controller.dart';

/// Selects words directly on the page photo, like a camera text lens.
///
/// - Tap a word to select or deselect it.
/// - Touch and hold a word, then drag to another word, to select the words
///   between them as one expression.
/// - Drag with one finger to move, pinch to zoom. Selection gestures and
///   zooming never conflict: selecting by dragging starts only after a hold.
/// - "Select area": draw a box around text that was not recognized well;
///   that part of the photo is read again and offered for correction.
///
/// Word boxes come from on-device OCR in image pixels and are mapped to the
/// screen with [ImageFit]; zoom and pan transform image and boxes together.
class ScanImageSelectView extends ConsumerStatefulWidget {
  const ScanImageSelectView({super.key, required this.initialDeckId});

  final String? initialDeckId;

  @override
  ConsumerState<ScanImageSelectView> createState() =>
      _ScanImageSelectViewState();
}

class _ScanImageSelectViewState extends ConsumerState<ScanImageSelectView> {
  final _transform = TransformationController();
  bool _regionMode = false;
  TextToken? _dragFrom;
  TextToken? _dragTo;
  Offset? _regionStart;
  Offset? _regionEnd;
  ImageFit? _fit;

  /// Finger tolerance around word boxes, in logical pixels on screen.
  static const _touchSlop = 10.0;

  late final _provider = scanControllerProvider(widget.initialDeckId);

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// The word token under [viewportPoint] (a point in the viewer, before
  /// zoom and pan are undone).
  TextToken? _tokenAt(ScanDocument document, Offset viewportPoint) {
    final fit = _fit;
    if (fit == null) return null;
    final scene = _transform.toScene(viewportPoint);
    final zoom = _transform.value.getMaxScaleOnAxis();
    return document.tokenAt(
      fit.toImage(scene),
      slop: _touchSlop / (fit.scale * zoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final document = state.document!;
    final image = state.image!;
    final imageSize = document.scanText.imageSize!;

    ref.listen(_provider.select((s) => s.regionText), (_, text) {
      if (text != null) _confirmRegionText(text);
    });

    final notice = switch (state.notice) {
      SelectionNotice.expressionTooLong => l10n.scanExpressionTooLong(
        AppConfig.maxExpressionWords,
      ),
      SelectionNotice.regionEmpty => l10n.scanRegionEmpty,
      SelectionNotice.regionFailed => l10n.scanRegionFailed,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.xs,
            AppSpace.gutter,
            AppSpace.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _regionMode ? l10n.scanRegionHint : l10n.scanImageHint,
                key: const Key('scan.imageHint'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              FilterChip(
                key: const Key('scan.regionMode'),
                avatar: const Icon(Icons.crop_free, size: 18),
                label: Text(l10n.scanRegionMode),
                selected: _regionMode,
                onSelected: (value) => setState(() {
                  _regionMode = value;
                  _regionStart = _regionEnd = null;
                }),
              ),
            ],
          ),
        ),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            child: InfoBanner(
              key: const Key('scan.notice'),
              tone: StatusTone.warning,
              message: notice,
            ),
          ),
        Expanded(
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewport = constraints.biggest;
                final fit = _fit = ImageFit.contain(imageSize, viewport);
                final preview = switch ((_dragFrom, _dragTo)) {
                  (final from?, final to?) when from.start == to.start =>
                    document.rangeOfWord(from),
                  (final from?, final to?) => document.rangeBetween(
                    from,
                    to,
                    maxWords: AppConfig.maxExpressionWords,
                  ),
                  _ => null,
                };
                return Stack(
                  children: [
                    GestureDetector(
                      key: const Key('scan.page'),
                      onTapUp: _regionMode
                          ? null
                          : (d) {
                              final token = _tokenAt(document, d.localPosition);
                              if (token != null) controller.toggleWord(token);
                            },
                      onLongPressStart: _regionMode
                          ? null
                          : (d) {
                              final token = _tokenAt(document, d.localPosition);
                              if (token == null) return;
                              HapticFeedback.selectionClick();
                              setState(() => _dragFrom = _dragTo = token);
                            },
                      onLongPressMoveUpdate: _regionMode
                          ? null
                          : (d) {
                              if (_dragFrom == null) return;
                              final token = _tokenAt(document, d.localPosition);
                              if (token != null &&
                                  token.start != _dragTo?.start) {
                                setState(() => _dragTo = token);
                              }
                            },
                      onLongPressEnd: _regionMode
                          ? null
                          : (_) {
                              final (from, to) = (_dragFrom, _dragTo);
                              setState(() => _dragFrom = _dragTo = null);
                              if (from != null && to != null) {
                                controller.selectBetween(from, to);
                              }
                            },
                      child: InteractiveViewer(
                        transformationController: _transform,
                        minScale: 1,
                        maxScale: 8,
                        child: SizedBox.fromSize(
                          size: viewport,
                          child: Stack(
                            children: [
                              Positioned.fromRect(
                                rect: fit.imageRect,
                                child: Image(
                                  key: const Key('scan.pageImage'),
                                  image: ref.watch(scanPageImageProvider)(
                                    image,
                                  ),
                                  fit: BoxFit.fill,
                                  semanticLabel: l10n.scanPageImageLabel,
                                  errorBuilder: (_, _, _) =>
                                      const ColoredBox(color: Colors.black12),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  key: const Key('scan.overlay'),
                                  painter: _PageOverlayPainter(
                                    fit: fit,
                                    document: document,
                                    selection: state.selection,
                                    preview: preview,
                                    region:
                                        _regionStart == null ||
                                            _regionEnd == null
                                        ? null
                                        : Rect.fromPoints(
                                            _regionStart!,
                                            _regionEnd!,
                                          ),
                                    colors: _OverlayColors.of(context),
                                    onToggle: controller.toggleWord,
                                    selectHint: l10n.scanWordTapToSelect,
                                    deselectHint: l10n.scanWordTapToDeselect,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_regionMode)
                      Positioned.fill(
                        child: GestureDetector(
                          key: const Key('scan.regionCanvas'),
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) => setState(() {
                            _regionStart = _transform.toScene(d.localPosition);
                            _regionEnd = _regionStart;
                          }),
                          onPanUpdate: (d) => setState(
                            () => _regionEnd = _transform.toScene(
                              d.localPosition,
                            ),
                          ),
                          onPanEnd: (_) => _finishRegion(fit),
                        ),
                      ),
                    if (state.regionBusy)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x33000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        _SelectedWords(state: state, controller: controller),
        _BottomBar(state: state, controller: controller),
      ],
    );
  }

  void _finishRegion(ImageFit fit) {
    final (start, end) = (_regionStart, _regionEnd);
    setState(() => _regionStart = _regionEnd = null);
    if (start == null || end == null) return;
    final rect = fit.toImageRect(Rect.fromPoints(start, end));
    // Ignore accidental touches: at least ~12 logical pixels each way.
    final minSide = 12 / fit.scale;
    if (rect.isEmpty || rect.width < minSide || rect.height < minSide) return;
    ref.read(_provider.notifier).recognizeRegion(rect);
  }

  Future<void> _confirmRegionText(String text) async {
    final controller = ref.read(_provider.notifier);
    final added = await showDialog<String>(
      context: context,
      builder: (context) => _RegionTextDialog(text: text),
    );
    if (!mounted) return;
    if (added == null) {
      controller.dismissRegionText();
    } else {
      controller.addRegionText(added, context: text);
    }
  }
}

/// Shows the text read from a drawn area for correction before adding it.
class _RegionTextDialog extends StatefulWidget {
  const _RegionTextDialog({required this.text});

  final String text;

  @override
  State<_RegionTextDialog> createState() => _RegionTextDialogState();
}

class _RegionTextDialogState extends State<_RegionTextDialog> {
  late final _field = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.scanRegionTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          key: const Key('scan.regionText'),
          controller: _field,
          textDirection: TextDirection.ltr,
          style: AppTypography.germanBody,
          minLines: 1,
          maxLines: 6,
          autofocus: true,
          decoration: InputDecoration(helperText: l10n.scanRegionHelper),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('scan.regionCancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('scan.regionAdd'),
          onPressed: () => Navigator.pop(context, _field.text),
          child: Text(l10n.scanRegionAdd),
        ),
      ],
    );
  }
}

/// The selections as removable chips, in reading order; area items last.
class _SelectedWords extends StatelessWidget {
  const _SelectedWords({required this.state, required this.controller});

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final document = state.document!;
    if (state.selectedCount == 0) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 112),
      child: SingleChildScrollView(
        key: const Key('scan.selectedList'),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          0,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final range in state.selection.ranges)
                _chip(
                  context,
                  key: Key('scan.chip.${range.start}'),
                  label: document.selectedText(range),
                  onDeleted: () => controller.removeRange(range),
                  onPressed: _isExpression(document, range)
                      ? () => _expressionActions(context, range)
                      : null,
                  deleteTooltip: l10n.scanRemoveSelection,
                ),
              for (final item in state.manualItems)
                _chip(
                  context,
                  key: Key('scan.manualChip.${item.id}'),
                  label: item.original,
                  icon: Icons.crop_free,
                  onDeleted: () => controller.removeManualItem(item.id),
                  deleteTooltip: l10n.scanRemoveSelection,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isExpression(ScanDocument document, SelectedRange range) =>
      document.words
          .where((w) => w.start >= range.start && w.end <= range.end)
          .length >
      1;

  Widget _chip(
    BuildContext context, {
    required Key key,
    required String label,
    required VoidCallback onDeleted,
    required String deleteTooltip,
    VoidCallback? onPressed,
    IconData? icon,
  }) => InputChip(
    key: key,
    avatar: icon == null
        ? (onPressed == null ? null : const Icon(Icons.more_horiz, size: 18))
        : Icon(icon, size: 18),
    label: Text(label, style: AppTypography.germanBody),
    onPressed: onPressed,
    onDeleted: onDeleted,
    deleteButtonTooltipMessage: deleteTooltip,
  );

  Future<void> _expressionActions(
    BuildContext context,
    SelectedRange range,
  ) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('scan.splitWords'),
              leading: const Icon(Icons.call_split),
              title: Text(l10n.scanSplitWords),
              onTap: () => Navigator.pop(context, 'split'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.scanRemoveSelection),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'split':
        controller.splitRange(range);
      case 'remove':
        controller.removeRange(range);
    }
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.controller});

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
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
            AppSpace.sm,
            AppSpace.gutter,
            AppSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.scanSelectedCount(state.selectedCount),
                  key: const Key('scan.selectedCount'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              FilledButton(
                key: const Key('scan.review'),
                onPressed: state.selectedCount == 0
                    ? null
                    : controller.goToReview,
                child: Text(l10n.scanReviewButton(state.selectedCount)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayColors {
  const _OverlayColors({
    required this.outline,
    required this.selected,
    required this.selectedBorder,
    required this.preview,
    required this.region,
  });

  factory _OverlayColors.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    return _OverlayColors(
      outline: scheme.primary.withValues(alpha: 0.45),
      selected: colors.highlight.withValues(alpha: 0.55),
      selectedBorder: scheme.primary,
      preview: scheme.tertiary.withValues(alpha: 0.35),
      region: scheme.secondary,
    );
  }

  final Color outline;
  final Color selected;
  final Color selectedBorder;
  final Color preview;
  final Color region;

  @override
  bool operator ==(Object other) =>
      other is _OverlayColors &&
      other.outline == outline &&
      other.selected == selected &&
      other.selectedBorder == selectedBorder &&
      other.preview == preview &&
      other.region == region;

  @override
  int get hashCode =>
      Object.hash(outline, selected, selectedBorder, preview, region);
}

/// Word boxes, selections, the drag preview and the drawn area, in the
/// untransformed viewer coordinates (the viewer zooms them with the photo).
/// Also exposes each word to screen readers as a selectable button.
class _PageOverlayPainter extends CustomPainter {
  _PageOverlayPainter({
    required this.fit,
    required this.document,
    required this.selection,
    required this.preview,
    required this.region,
    required this.colors,
    required this.onToggle,
    required this.selectHint,
    required this.deselectHint,
  });

  final ImageFit fit;
  final ScanDocument document;
  final WordSelection selection;
  final SelectedRange? preview;
  final Rect? region;
  final _OverlayColors colors;
  final ValueChanged<TextToken> onToggle;
  final String selectHint;
  final String deselectHint;

  static const _radius = Radius.circular(3);

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.outline;
    for (final word in document.recognizedWords) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(fit.toViewRect(word.box), _radius),
        outline,
      );
    }
    final fill = Paint()..color = colors.selected;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = colors.selectedBorder;
    for (final range in selection.ranges) {
      for (final box in document.boxesOf(range)) {
        final r = RRect.fromRectAndRadius(fit.toViewRect(box), _radius);
        canvas
          ..drawRRect(r, fill)
          ..drawRRect(r, border);
      }
    }
    if (preview case final range?) {
      final paint = Paint()..color = colors.preview;
      for (final box in document.boxesOf(range)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(fit.toViewRect(box), _radius),
          paint,
        );
      }
    }
    if (region case final r?) {
      canvas
        ..drawRect(r, Paint()..color = colors.region.withValues(alpha: 0.15))
        ..drawRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = colors.region,
        );
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final nodes = <CustomPainterSemantics>[];
    final seen = <int>{};
    for (final word in document.recognizedWords) {
      final token = document.tokenFor(word);
      if (token == null || !seen.add(token.start)) continue;
      final boxes = [
        for (final w in document.recognizedWords)
          if (document.tokenFor(w)?.start == token.start) w.box,
      ];
      final rect = boxes
          .map(fit.toViewRect)
          .reduce((a, b) => a.expandToInclude(b));
      final selected = selection.rangeAt(token.start) != null;
      nodes.add(
        CustomPainterSemantics(
          key: ValueKey(('scan.box', token.start)),
          rect: rect,
          properties: SemanticsProperties(
            label: token.display,
            button: true,
            selected: selected,
            textDirection: TextDirection.ltr,
            hintOverrides: SemanticsHintOverrides(
              onTapHint: selected ? deselectHint : selectHint,
            ),
            onTap: () => onToggle(token),
          ),
        ),
      );
    }
    return nodes;
  };

  @override
  bool shouldRepaint(_PageOverlayPainter old) =>
      old.fit != fit ||
      old.document != document ||
      old.selection != selection ||
      old.preview != preview ||
      old.region != region ||
      old.colors != colors;

  @override
  bool shouldRebuildSemantics(_PageOverlayPainter old) =>
      old.fit != fit || old.document != document || old.selection != selection;
}
