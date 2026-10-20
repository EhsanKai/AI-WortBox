import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../app/providers.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/state_views.dart' show ButtonProgress;
import '../../../l10n/app_localizations.dart';
import '../domain/highlight.dart';
import '../domain/image_fit.dart';
import 'scan_controller.dart';

enum _Mode { highlight, rectangle, move }

/// The page photo, unchanged, with the user's own highlights and
/// rectangles drawn over it.
///
/// - Highlight mode: one finger draws a translucent stroke over words (a tap
///   marks the word under the finger); two fingers zoom and move.
/// - Rectangle mode: one finger drags a rectangle around text; everything
///   readable inside it is read. Two fingers zoom and move.
/// - Move mode: one finger moves the page, two fingers zoom; nothing is
///   drawn.
///
/// Drawing follows raw pointers, not the zoom gesture: only the finger that
/// started a stroke or rectangle extends it, and it is kept only when that
/// finger lifts without any other finger having touched the page meanwhile.
/// As soon as a second finger touches, the draft is discarded and nothing
/// is drawn until all fingers are lifted, so a pinch never leaves a mark
/// (and positions of different fingers are never joined).
///
/// Selections are stored in photo pixels ([HighlightStroke],
/// [RegionSelection]); the overlay is drawn in the viewer's coordinates and
/// zoomed together with the photo. The photo file is never modified. OCR
/// runs only when the user taps "Read selected text", and only on the
/// selected parts.
class ScanHighlightView extends ConsumerStatefulWidget {
  const ScanHighlightView({super.key, required this.initialDeckId});

  final String? initialDeckId;

  @override
  ConsumerState<ScanHighlightView> createState() => _ScanHighlightViewState();
}

class _ScanHighlightViewState extends ConsumerState<ScanHighlightView> {
  /// Brush width on screen, in logical pixels, at any zoom.
  static const brushWidth = 20.0;

  /// Shortest side of a rectangle on screen, in logical pixels; smaller
  /// drags (a tap, a slip) are ignored.
  static const minRectangleSide = 12.0;

  late final _provider = scanControllerProvider(widget.initialDeckId);
  final _transform = TransformationController();
  _Mode _mode = _Mode.highlight;
  ImageFit? _fit;

  // Pointer state: the fingers on the drawing surface, the one drawing the
  // draft, and whether several fingers touched since all were last lifted.
  final _pointers = <int>{};
  int? _drawingPointer;
  bool _multiTouch = false;

  // The draft, in photo pixels: a stroke's points, or a rectangle's corners.
  List<Offset>? _drawing;
  double _drawingWidth = 0;
  (Offset, Offset)? _framing;

  // Zoom state (two fingers or more).
  int _zoomPointers = 0;
  double _zoomBase = 1;
  Offset _zoomFocus = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  double get _zoom => _transform.value.getMaxScaleOnAxis();

  /// [viewportPoint] (inside the viewer, on screen) in photo pixels.
  Offset _toImage(Offset viewportPoint) =>
      _fit!.toImageThrough(_transform.value, viewportPoint);

  bool get _hasDraft => _drawing != null || _framing != null;

  void _discardDraft() {
    _drawingPointer = null;
    if (_hasDraft) {
      setState(() {
        _drawing = null;
        _framing = null;
      });
    }
  }

  /// Forgets all fingers and any draft, e.g. when the drawing surface goes
  /// away (mode change, reading) and their lift events will never arrive.
  void _resetPointers() {
    _pointers.clear();
    _multiTouch = false;
    _drawingPointer = null;
    _drawing = null;
    _framing = null;
    _zoomPointers = 0;
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers.add(e.pointer);
    if (_pointers.length > 1) {
      // A second finger: this is a zoom or pan, never a selection.
      _multiTouch = true;
      _discardDraft();
      return;
    }
    if (_multiTouch || _fit == null) return;
    _drawingPointer = e.pointer;
    final at = _toImage(e.localPosition);
    setState(() {
      if (_mode == _Mode.rectangle) {
        _framing = (at, at);
      } else {
        _drawingWidth = brushWidth / (_fit!.scale * _zoom);
        _drawing = [at];
      }
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _drawingPointer || _multiTouch) return;
    final at = _toImage(e.localPosition);
    setState(() {
      if (_framing case (final from, _)) {
        _framing = (from, at);
      } else if (_drawing case final points?) {
        _drawing = [...points, at];
      }
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    final commit = e.pointer == _drawingPointer && !_multiTouch;
    _pointersLifted(e.pointer);
    if (commit) {
      _commitDraft();
    } else if (e.pointer == _drawingPointer) {
      _discardDraft();
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    final drawing = e.pointer == _drawingPointer;
    _pointersLifted(e.pointer);
    if (drawing) _discardDraft();
  }

  void _pointersLifted(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isEmpty) _multiTouch = false;
  }

  void _commitDraft() {
    final points = _drawing;
    final framing = _framing;
    setState(() {
      _drawing = null;
      _framing = null;
    });
    _drawingPointer = null;
    final controller = ref.read(_provider.notifier);
    if (points != null && points.isNotEmpty) {
      controller.addStroke(points, _drawingWidth);
    } else if (framing case (final a, final b)) {
      // Measured on screen, so the minimum does not depend on the zoom.
      final side = minRectangleSide / (_fit!.scale * _zoom);
      final size = (b - a);
      if (size.dx.abs() >= side && size.dy.abs() >= side) {
        controller.addRegion(a, b);
      }
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _zoomPointers = d.pointerCount;
    if (d.pointerCount >= 2) _beginZoom(d.localFocalPoint);
  }

  /// Only two or more fingers zoom and move here; one finger draws (see
  /// the pointer handlers), so single-finger updates are ignored.
  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount < 2) {
      _zoomPointers = d.pointerCount;
      return;
    }
    if (_zoomPointers != d.pointerCount) _beginZoom(d.localFocalPoint);
    _zoomPointers = d.pointerCount;
    _zoomTo(d.scale, d.localFocalPoint);
  }

  void _beginZoom(Offset focal) {
    _zoomBase = _zoom;
    _zoomFocus = _transform.toScene(focal);
  }

  /// Zooms around the fingers, keeping the photo inside the viewer.
  void _zoomTo(double relativeScale, Offset focal) {
    final viewport = _fit!.viewport;
    final s = (_zoomBase * relativeScale).clamp(1.0, 8.0);
    final tx = (focal.dx - _zoomFocus.dx * s).clamp(
      viewport.width * (1 - s),
      0.0,
    );
    final ty = (focal.dy - _zoomFocus.dy * s).clamp(
      viewport.height * (1 - s),
      0.0,
    );
    _transform.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);
    final image = state.image!;
    final imageSize = state.imageSize!;
    final drawing = _mode != _Mode.move && !state.isBusy;
    if (!drawing) _resetPointers();

    final notice = switch (state.notice) {
      SelectionNotice.highlightsEmpty => l10n.scanHighlightsEmpty,
      SelectionNotice.regionsEmpty => l10n.scanRegionsEmpty,
      SelectionNotice.highlightsFailed => l10n.scanHighlightsFailed,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.xs,
            AppSpace.xs,
            0,
          ),
          // Two rows on narrow screens, so every button keeps its full size.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<_Mode>(
                key: const Key('scan.mode'),
                showSelectedIcon: false,
                // Narrow icon segments (48 instead of Material's 64 px
                // minimum), so the modes and the actions fit in one row on
                // small phones; each stays a full touch target.
                style: SegmentedButton.styleFrom(
                  visualDensity: const VisualDensity(horizontal: -4),
                ),
                segments: [
                  ButtonSegment(
                    value: _Mode.highlight,
                    icon: const Icon(
                      Icons.brush_outlined,
                      key: Key('scan.modeHighlight'),
                    ),
                    tooltip: l10n.scanModeHighlight,
                  ),
                  ButtonSegment(
                    value: _Mode.rectangle,
                    icon: const Icon(
                      Icons.crop_free,
                      key: Key('scan.modeRectangle'),
                    ),
                    tooltip: l10n.scanModeRectangle,
                  ),
                  ButtonSegment(
                    value: _Mode.move,
                    icon: const Icon(
                      Icons.pan_tool_outlined,
                      key: Key('scan.modeMove'),
                    ),
                    tooltip: l10n.scanModeMove,
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() {
                  _resetPointers();
                  _mode = s.first;
                }),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('scan.undo'),
                    tooltip: l10n.scanUndoStroke,
                    icon: const Icon(Icons.undo),
                    onPressed: !state.hasPhotoSelections || state.isBusy
                        ? null
                        : controller.undoPhotoSelection,
                  ),
                  IconButton(
                    key: const Key('scan.clearHighlights'),
                    tooltip: l10n.scanClearHighlights,
                    icon: const Icon(Icons.layers_clear_outlined),
                    onPressed: !state.hasPhotoSelections || state.isBusy
                        ? null
                        : controller.clearPhotoSelections,
                  ),
                  PopupMenuButton<String>(
                    key: const Key('scan.more'),
                    tooltip: l10n.scanMoreActions,
                    enabled: !state.isBusy,
                    onSelected: (action) => switch (action) {
                      'page' => controller.readWholePage(),
                      'type' => controller.startTyping(),
                      _ => null,
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        key: const Key('scan.wholePage'),
                        value: 'page',
                        child: Text(l10n.scanReadWholePage),
                      ),
                      PopupMenuItem(
                        value: 'type',
                        child: Text(l10n.scanTypeText),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.xxs,
            AppSpace.gutter,
            AppSpace.xs,
          ),
          child: Text(
            switch (_mode) {
              _Mode.highlight => l10n.scanHighlightHint,
              _Mode.rectangle => l10n.scanRectangleHint,
              _Mode.move => l10n.scanMoveHint,
            },
            key: const Key('scan.modeHint'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (notice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.xs,
            ),
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
                return Stack(
                  children: [
                    InteractiveViewer(
                      key: const Key('scan.page'),
                      transformationController: _transform,
                      minScale: 1,
                      maxScale: 8,
                      child: SizedBox.fromSize(
                        size: viewport,
                        child: Stack(
                          children: [
                            Positioned.fromRect(
                              rect: fit.imageRect,
                              // The original photo, at its own aspect
                              // ratio; nothing is drawn into it.
                              child: Image(
                                key: const Key('scan.pageImage'),
                                image: ref.watch(scanPageImageProvider)(image),
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                                semanticLabel: l10n.scanPageImageLabel,
                                errorBuilder: (_, _, _) =>
                                    const ColoredBox(color: Colors.black12),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  key: const Key('scan.highlights'),
                                  painter: _HighlightPainter(
                                    fit: fit,
                                    strokes: state.strokes,
                                    regions: state.regions,
                                    numbers: {
                                      for (final id in state.photoSelectionIds)
                                        id: state.selectionNumber(id),
                                    },
                                    failed: state.failedStrokes,
                                    drawing: _drawing,
                                    drawingWidth: _drawingWidth,
                                    framing: _framing,
                                    colors: _HighlightColors.of(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (drawing)
                      Positioned.fill(
                        child: Listener(
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerCancel,
                          child: GestureDetector(
                            key: const Key('scan.drawSurface'),
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _onScaleStart,
                            onScaleUpdate: _onScaleUpdate,
                            onScaleEnd: (_) => _zoomPointers = 0,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        _StrokeChips(state: state, controller: controller),
        _BottomBar(state: state, controller: controller),
      ],
    );
  }
}

/// One chip per highlight or rectangle, numbered as on the photo,
/// removable.
class _StrokeChips extends StatelessWidget {
  const _StrokeChips({required this.state, required this.controller});

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    if (!state.hasPhotoSelections) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final regionIds = {for (final r in state.regions) r.id};
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 96),
      child: SingleChildScrollView(
        key: const Key('scan.strokeList'),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xs,
          AppSpace.gutter,
          0,
        ),
        child: Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final (i, id) in state.photoSelectionIds.indexed)
              InputChip(
                key: Key(
                  regionIds.contains(id)
                      ? 'scan.region.$id'
                      : 'scan.stroke.$id',
                ),
                avatar: state.failedStrokes.contains(id)
                    ? Icon(Icons.error_outline, color: theme.colorScheme.error)
                    : Icon(
                        regionIds.contains(id)
                            ? Icons.crop_free
                            : Icons.brush_outlined,
                        size: 18,
                      ),
                label: Text(
                  regionIds.contains(id)
                      ? l10n.scanRegionLabel(numbers.format(i + 1))
                      : l10n.scanHighlightLabel(numbers.format(i + 1)),
                ),
                onDeleted: state.isBusy
                    ? null
                    : () => controller.removePhotoSelection(id),
                deleteButtonTooltipMessage: l10n.scanRemoveSelection,
              ),
          ],
        ),
      ),
    );
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
                  l10n.scanHighlightCount(state.photoSelectionIds.length),
                  key: const Key('scan.highlightCount'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              FilledButton.icon(
                key: const Key('scan.readHighlights'),
                onPressed:
                    state.isBusy ||
                        (!state.hasPhotoSelections && state.manualItems.isEmpty)
                    ? null
                    : controller.readHighlights,
                icon: const Icon(Icons.text_fields),
                label: state.isBusy
                    ? const ButtonProgress()
                    : Text(l10n.scanReadHighlights),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightColors {
  const _HighlightColors(
    this.stroke,
    this.failed,
    this.badge,
    this.onBadge,
    this.frame,
  );

  factory _HighlightColors.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _HighlightColors(
      // Translucent so the printed words stay readable underneath.
      const Color(0xFFFFD54F).withValues(alpha: 0.42),
      scheme.error.withValues(alpha: 0.35),
      scheme.primary,
      scheme.onPrimary,
      scheme.primary,
    );
  }

  final Color stroke;
  final Color failed;
  final Color badge;
  final Color onBadge;

  /// Outline of rectangles (filled translucently).
  final Color frame;

  @override
  bool operator ==(Object other) =>
      other is _HighlightColors &&
      other.stroke == stroke &&
      other.failed == failed &&
      other.badge == badge &&
      other.onBadge == onBadge &&
      other.frame == frame;

  @override
  int get hashCode => Object.hash(stroke, failed, badge, onBadge, frame);
}

/// Draws the highlights and rectangles (photo pixels → viewer coordinates)
/// and a number next to each, matching the chips. Only an overlay: the
/// photo is a separate widget underneath and is never painted on.
class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.fit,
    required this.strokes,
    required this.regions,
    required this.numbers,
    required this.failed,
    required this.drawing,
    required this.drawingWidth,
    required this.framing,
    required this.colors,
  });

  final ImageFit fit;
  final List<HighlightStroke> strokes;
  final List<RegionSelection> regions;

  /// Number shown for each selection id.
  final Map<int, int> numbers;
  final Set<int> failed;
  final List<Offset>? drawing;
  final double drawingWidth;

  /// Corners of the rectangle being drawn, in photo pixels.
  final (Offset, Offset)? framing;
  final _HighlightColors colors;

  void _paintStroke(Canvas canvas, List<Offset> points, double width, Color c) {
    final paint = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * fit.scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final view = [for (final p in points) fit.toView(p)];
    if (view.length == 1 || view.every((p) => p == view.first)) {
      canvas.drawCircle(
        view.first,
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path()..moveTo(view.first.dx, view.first.dy);
    for (final p in view.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintFrame(Canvas canvas, Rect imageRect, {required bool isFailed}) {
    final rect = fit.toViewRect(imageRect);
    final color = isFailed ? colors.failed : colors.frame;
    canvas
      ..drawRect(rect, Paint()..color = color.withValues(alpha: 0.12))
      ..drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  void _paintBadge(Canvas canvas, Offset at, int number) {
    final label = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: colors.onBadge,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawCircle(at, 8, Paint()..color = colors.badge);
    label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _paintStroke(
        canvas,
        s.points,
        s.width,
        failed.contains(s.id) ? colors.failed : colors.stroke,
      );
      final at =
          fit.toView(s.points.first) -
          Offset(s.width * fit.scale * 0.6, s.width * fit.scale * 0.6);
      _paintBadge(canvas, at, numbers[s.id] ?? 0);
    }
    for (final r in regions) {
      _paintFrame(canvas, r.rect, isFailed: failed.contains(r.id));
      _paintBadge(canvas, fit.toView(r.rect.topLeft), numbers[r.id] ?? 0);
    }
    if (drawing case final points?) {
      _paintStroke(canvas, points, drawingWidth, colors.stroke);
    }
    if (framing case (final a, final b)) {
      final rect = Rect.fromPoints(a, b).intersect(Offset.zero & fit.imageSize);
      if (!rect.isEmpty) _paintFrame(canvas, rect, isFailed: false);
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.fit != fit ||
      old.strokes != strokes ||
      old.regions != regions ||
      !mapEquals(old.numbers, numbers) ||
      old.failed != failed ||
      old.drawing != drawing ||
      old.framing != framing ||
      old.colors != colors;
}
