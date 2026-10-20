import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../vocabulary/domain/duplicate_detection.dart';
import '../../vocabulary/domain/vocabulary_repository.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../data/scan_image_source.dart';
import '../domain/highlight.dart';
import '../domain/lemma_hints.dart';
import '../domain/scan_document.dart';
import '../domain/scan_review_item.dart';
import '../domain/scan_text.dart';
import '../domain/text_tokenizer.dart';
import '../domain/word_selection.dart';

/// capture → highlight (photo) or typing → select (text) → review → done.
enum ScanStep { capture, typing, highlight, select, review, done }

enum SelectionMode { word, expression }

/// Short-lived messages for the selection screens.
enum SelectionNotice {
  pickExpressionEnd,
  expressionTooLong,
  selectionsDropped,

  /// No highlight contained readable text.
  highlightsEmpty,

  /// No rectangle contained readable text (only rectangles were read).
  regionsEmpty,

  /// Reading the highlights failed (OCR error).
  highlightsFailed,

  /// The photo could not be shown, so the whole page was read as text.
  photoUnavailable,
}

@immutable
class ScanState {
  const ScanState({
    this.step = ScanStep.capture,
    this.isBusy = false,
    this.error,
    this.document,
    this.selection = const WordSelection(),
    this.mode = SelectionMode.word,
    this.anchor,
    this.notice,
    this.droppedCount = 0,
    this.items = const [],
    this.deckId,
    this.strategy = DuplicateStrategy.skip,
    this.result,
    this.saveError,
    this.image,
    this.imageSize,
    this.strokes = const [],
    this.regions = const [],
    this.readStrokes = const {},
    this.failedStrokes = const {},
    this.manualItems = const [],
  });

  final ScanStep step;

  /// Picking an image, recognizing text or saving.
  final bool isBusy;

  /// Problem while picking or recognizing (capture step).
  final Object? error;

  /// Text to select from (typed text, or the whole page read on request).
  final ScanDocument? document;
  final WordSelection selection;
  final SelectionMode mode;

  /// First word of an expression being selected.
  final TextToken? anchor;
  final SelectionNotice? notice;
  final int droppedCount;

  /// Items on the review screen. Text selections carry their range;
  /// items read from highlights or added by hand have none.
  final List<(SelectedRange?, ScanReviewItem)> items;
  final String? deckId;
  final DuplicateStrategy strategy;
  final ImportSummary? result;
  final Object? saveError;

  /// The page photo, unchanged, kept only while this scan is open.
  final PickedImage? image;

  /// Its pixel size as displayed (upright).
  final Size? imageSize;

  /// Highlights drawn on the photo, in drawing order.
  final List<HighlightStroke> strokes;

  /// Rectangles drawn on the photo, in drawing order. They share the ids
  /// (and numbering) of [strokes].
  final List<RegionSelection> regions;

  /// Highlights and rectangles already read by OCR (not read again).
  final Set<int> readStrokes;

  /// Highlights and rectangles in which no text was recognized.
  final Set<int> failedStrokes;

  /// Items without a text range: read from highlights or added by hand.
  final List<ScanReviewItem> manualItems;

  /// Text selections plus items without a range.
  int get selectedCount => selection.length + manualItems.length;

  /// Whether anything is highlighted or framed on the photo.
  bool get hasPhotoSelections => strokes.isNotEmpty || regions.isNotEmpty;

  /// Ids of all highlights and rectangles, in drawing order.
  List<int> get photoSelectionIds =>
      [for (final s in strokes) s.id, for (final r in regions) r.id]..sort();

  /// Position (1-based) of highlight or rectangle [id] in drawing order, as
  /// shown to the user.
  int selectionNumber(int id) => photoSelectionIds.indexOf(id) + 1;

  ScanState copyWith({
    ScanStep? step,
    bool? isBusy,
    ScanDocument? document,
    WordSelection? selection,
    SelectionMode? mode,
    List<(SelectedRange?, ScanReviewItem)>? items,
    String? deckId,
    DuplicateStrategy? strategy,
    List<HighlightStroke>? strokes,
    List<RegionSelection>? regions,
    Set<int>? readStrokes,
    Set<int>? failedStrokes,
    List<ScanReviewItem>? manualItems,
  }) => ScanState(
    step: step ?? this.step,
    isBusy: isBusy ?? this.isBusy,
    document: document ?? this.document,
    selection: selection ?? this.selection,
    mode: mode ?? this.mode,
    // Transient fields (anchor, notice, errors) are cleared by default.
    anchor: null,
    items: items ?? this.items,
    deckId: deckId ?? this.deckId,
    strategy: strategy ?? this.strategy,
    result: result,
    image: image,
    imageSize: imageSize,
    strokes: strokes ?? this.strokes,
    regions: regions ?? this.regions,
    readStrokes: readStrokes ?? this.readStrokes,
    failedStrokes: failedStrokes ?? this.failedStrokes,
    manualItems: manualItems ?? this.manualItems,
  );
}

class ScanController extends Notifier<ScanState> {
  ScanController(this.initialDeckId);

  final String? initialDeckId;
  bool _recoveryChecked = false;
  late ScanImageSource _source;

  /// The photo kept for highlighting; see [ScanState.image].
  PickedImage? _kept;
  int _lastItemId = 0;
  int _lastStrokeId = 0;

  @override
  ScanState build() {
    _source = ref.read(scanImageSourceProvider);
    ref.onDispose(_discardKept);
    return ScanState(deckId: initialDeckId);
  }

  void _discardKept() {
    final image = _kept;
    _kept = null;
    if (image != null) _source.discard(image);
  }

  // ---------------------------------------------------------------------------
  // Capture

  /// On Android, recovers a photo taken before the system killed the app.
  Future<void> recoverLostImage() async {
    if (_recoveryChecked) return;
    _recoveryChecked = true;
    final image = await ref.read(scanImageSourceProvider).retrieveLost();
    if (image != null) await _openPhoto(image);
  }

  Future<void> pickImage(ImageOrigin origin) async {
    if (state.isBusy) return;
    _discardKept();
    state = ScanState(
      deckId: state.deckId,
      strategy: state.strategy,
      isBusy: true,
    );
    try {
      final image = await ref.read(scanImageSourceProvider).pick(origin);
      if (image == null) {
        state = state.copyWith(isBusy: false);
        return;
      }
      await _openPhoto(image);
    } on AppException catch (e) {
      _fail(e);
    }
  }

  /// Shows the photo for highlighting. Nothing is recognized yet: OCR runs
  /// only on the highlighted parts, when the user asks for it.
  Future<void> _openPhoto(PickedImage image) async {
    state = state.copyWith(isBusy: true);
    try {
      validatePickedImage(image);
    } on AppException catch (e) {
      await _source.discard(image);
      return _fail(e);
    }
    _kept = image;
    final Size size;
    try {
      size = await ref.read(imageCropperProvider).imageSize(image);
    } on AppException {
      // The photo cannot be displayed; reading the whole page is the only
      // way to use it, and the user is told so.
      return _readWholePage(image, notice: SelectionNotice.photoUnavailable);
    }
    if (!ref.mounted) return;
    state = ScanState(
      step: ScanStep.highlight,
      deckId: state.deckId,
      strategy: state.strategy,
      image: image,
      imageSize: size,
    );
  }

  void _fail(Object error) {
    _discardKept();
    state = ScanState(
      deckId: state.deckId,
      strategy: state.strategy,
      error: error,
    );
  }

  void startTyping() {
    _discardKept();
    state = ScanState(
      step: ScanStep.typing,
      deckId: state.deckId,
      strategy: state.strategy,
    );
  }

  /// Uses typed or pasted text instead of OCR.
  void useTypedText(String input) {
    final text = ScanText.typed(input);
    if (text.isBlank) return;
    _open(text);
  }

  void _open(ScanText text, {SelectionNotice? notice}) => state = ScanState(
    step: ScanStep.select,
    document: ScanDocument(text),
    deckId: state.deckId,
    strategy: state.strategy,
    notice: notice,
    image: state.image,
    imageSize: state.imageSize,
    strokes: state.strokes,
    regions: state.regions,
    readStrokes: state.readStrokes,
    failedStrokes: state.failedStrokes,
    manualItems: state.manualItems,
  );

  void backToCapture() {
    _discardKept();
    state = ScanState(deckId: state.deckId, strategy: state.strategy);
  }

  /// Back from the text view: to the photo when there is one.
  void backFromText() {
    if (state.image != null && state.imageSize != null) {
      state = state.copyWith(step: ScanStep.highlight);
    } else {
      backToCapture();
    }
  }

  // ---------------------------------------------------------------------------
  // Highlighting on the photo

  /// Adds a highlight drawn through [points] with a brush [width], both in
  /// photo pixels. Returns its id.
  int addStroke(List<Offset> points, double width) {
    if (points.isEmpty || width <= 0) return -1;
    final stroke = HighlightStroke(
      id: ++_lastStrokeId,
      points: List.unmodifiable(points),
      width: width,
    );
    state = state.copyWith(strokes: [...state.strokes, stroke]);
    return stroke.id;
  }

  /// Adds a rectangle spanned by [a] and [b] (photo pixels), clipped to
  /// the photo. Returns its id, or -1 when it is empty after clipping.
  int addRegion(Offset a, Offset b) {
    final size = state.imageSize;
    if (size == null) return -1;
    final rect = regionRectFor(a, b, size);
    if (rect == null) return -1;
    final region = RegionSelection(id: ++_lastStrokeId, rect: rect);
    state = state.copyWith(regions: [...state.regions, region]);
    return region.id;
  }

  /// Removes the last highlight or rectangle drawn.
  void undoPhotoSelection() {
    final ids = state.photoSelectionIds;
    if (ids.isNotEmpty) removePhotoSelection(ids.last);
  }

  /// Removes highlight or rectangle [id] and anything read from it.
  void removePhotoSelection(int id) => _dropSelections({id});

  void clearPhotoSelections() => _dropSelections({...state.photoSelectionIds});

  void _dropSelections(Set<int> ids) {
    final manual = [
      for (final item in state.manualItems)
        if (!ids.contains(item.stroke)) item,
    ];
    state = state.copyWith(
      strokes: [
        for (final s in state.strokes)
          if (!ids.contains(s.id)) s,
      ],
      regions: [
        for (final r in state.regions)
          if (!ids.contains(r.id)) r,
      ],
      readStrokes: state.readStrokes.difference(ids),
      failedStrokes: state.failedStrokes.difference(ids),
      manualItems: manual,
      items: _itemsWith(manual),
    );
  }

  /// Reads the highlighted and framed parts of the photo with on-device
  /// OCR, one crop per highlight or rectangle, and opens the review with the
  /// results in drawing order.
  ///
  /// A highlight yields the words its path ran through; a rectangle yields
  /// every readable line inside it (one item per line). Selections already
  /// read are not read again. A highlight without text is read once more
  /// with a larger margin; an empty highlight or rectangle is marked failed.
  /// The rest of the page is never read.
  Future<void> readHighlights() async {
    final image = state.image;
    final size = state.imageSize;
    if (image == null || size == null || state.isBusy) return;
    final pending = <Object>[
      for (final s in state.strokes)
        if (!state.readStrokes.contains(s.id)) s,
      for (final r in state.regions)
        if (!state.readStrokes.contains(r.id)) r,
    ];
    int idOf(Object selection) => switch (selection) {
      HighlightStroke(:final id) || RegionSelection(:final id) => id,
      _ => throw ArgumentError.value(selection),
    };
    pending.sort((a, b) => idOf(a).compareTo(idOf(b)));
    if (pending.isEmpty) {
      if (state.manualItems.isNotEmpty) _showReview();
      return;
    }
    final engine = ref.read(textRecognitionEngineProvider);
    if (!engine.isAvailable) {
      state = _withTransient(
        state.copyWith(),
        notice: SelectionNotice.highlightsFailed,
      );
      return;
    }
    state = state.copyWith(isBusy: true);
    final read = {...state.readStrokes};
    final failed = {...state.failedStrokes};
    final found = <ScanReviewItem>[];
    var errors = 0;
    for (final selection in pending) {
      final id = idOf(selection);
      var texts = const <HighlightText>[];
      var error = false;
      try {
        if (selection is HighlightStroke) {
          var text = await _read(image, size, selection, margin: 1);
          if (text == null || text.isEmpty) {
            text = await _read(image, size, selection, margin: 2);
          }
          texts = [?text];
        } else if (selection is RegionSelection) {
          texts = await _readRegion(image, selection.rect);
        }
      } on AppException {
        error = true;
        errors++;
      }
      if (!ref.mounted) return;
      texts = [
        for (final t in texts)
          if (!t.isEmpty) t,
      ];
      if (texts.isEmpty) {
        // After an OCR error the selection is read again next time; one
        // that simply contains no text is not.
        if (!error) read.add(id);
        failed.add(id);
        continue;
      }
      read.add(id);
      failed.remove(id);
      for (final text in texts) {
        found.add(
          ScanReviewItem(
            id: ++_lastItemId,
            original: text.text,
            context: text.context,
            hint: LemmaHints.suggest(text.text),
            stroke: id,
          ),
        );
      }
    }
    final manual = [...state.manualItems, ...found];
    final next = state.copyWith(
      isBusy: false,
      readStrokes: read,
      failedStrokes: failed,
      manualItems: manual,
      items: _itemsWith(manual),
    );
    if (manual.isEmpty) {
      state = _withTransient(
        next,
        notice: errors > 0
            ? SelectionNotice.highlightsFailed
            : pending.every((s) => s is RegionSelection)
            ? SelectionNotice.regionsEmpty
            : SelectionNotice.highlightsEmpty,
      );
      return;
    }
    state = next;
    _showReview();
  }

  /// Reads exactly [rect] (photo pixels, inside the photo): a temporary
  /// crop of it is recognized and deleted again.
  Future<List<HighlightText>> _readRegion(PickedImage image, Rect rect) async {
    if (rect.width < 1 || rect.height < 1) return const [];
    final crop = await ref.read(imageCropperProvider).crop(image, rect);
    try {
      return regionText(
        await ref.read(textRecognitionEngineProvider).recognize(crop.image),
      );
    } finally {
      await _source.discard(crop.image);
    }
  }

  Future<HighlightText?> _read(
    PickedImage image,
    Size size,
    HighlightStroke stroke, {
    required double margin,
  }) async {
    final region = ocrRegionFor(stroke, size, margin: margin);
    if (region.width < 1 || region.height < 1) return null;
    final crop = await ref.read(imageCropperProvider).crop(image, region);
    try {
      final recognized = await ref
          .read(textRecognitionEngineProvider)
          .recognize(crop.image);
      return highlightedText(
        stroke,
        recognized,
        region: crop.region,
        scale: crop.scale,
      );
    } finally {
      await _source.discard(crop.image);
    }
  }

  /// Reads the whole photo as text, only on the user's explicit request (or
  /// when the photo cannot be displayed). Highlights are kept.
  Future<void> readWholePage() async {
    final image = state.image;
    if (image == null || state.isBusy) return;
    await _readWholePage(image);
  }

  Future<void> _readWholePage(
    PickedImage image, {
    SelectionNotice? notice,
  }) async {
    state = state.copyWith(isBusy: true);
    try {
      final engine = ref.read(textRecognitionEngineProvider);
      if (!engine.isAvailable) {
        throw const ScanException(ScanError.ocrUnavailable);
      }
      final text = await engine.recognize(image);
      if (!ref.mounted) return;
      if (state.image == null) {
        // Photo not displayable: nothing to go back to.
        state = ScanState(
          deckId: state.deckId,
          strategy: state.strategy,
          image: image,
        );
      }
      _open(text, notice: notice);
    } on AppException catch (e) {
      if (state.step == ScanStep.highlight) {
        state = _withTransient(
          state.copyWith(isBusy: false),
          notice: SelectionNotice.highlightsFailed,
        );
      } else {
        _fail(e);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Selection in text

  void setMode(SelectionMode mode) => state = state.copyWith(mode: mode);

  void clearSelection() => state = state.copyWith(
    selection: const WordSelection(),
    items: _itemsWith(state.manualItems, selection: const WordSelection()),
  );

  void tapWord(TextToken word) {
    final document = state.document;
    if (document == null || !word.isWord) return;

    final existing = state.selection.rangeAt(word.start);
    if (state.mode == SelectionMode.word ||
        (state.anchor == null && existing != null)) {
      state = state.copyWith(
        selection: state.selection.toggle(document.rangeOfWord(word)),
      );
      return;
    }

    final anchor = state.anchor;
    if (anchor == null) {
      state = _withTransient(
        state.copyWith(),
        anchor: word,
        notice: SelectionNotice.pickExpressionEnd,
      );
      return;
    }
    if (anchor.start == word.start) {
      state = state.copyWith(); // Second tap on the anchor cancels.
      return;
    }
    final range = document.rangeBetween(
      anchor,
      word,
      maxWords: AppConfig.maxExpressionWords,
    );
    state = range == null
        ? _withTransient(
            state.copyWith(),
            notice: SelectionNotice.expressionTooLong,
          )
        : state.copyWith(selection: state.selection.add(range));
  }

  /// Replaces the text with a corrected version, keeping selections whose
  /// text did not change.
  void editText(String newText) {
    final document = state.document;
    if (document == null) return;
    final edited = document.scanText.edited(newText);
    if (edited.isBlank) return;
    final (selection, dropped) = state.selection.remap(
      document.text,
      edited.text,
    );
    state = _withTransient(
      state.copyWith(
        document: ScanDocument(edited),
        selection: selection,
        items: _itemsWith(state.manualItems, selection: const WordSelection()),
      ),
      notice: dropped > 0 ? SelectionNotice.selectionsDropped : null,
      droppedCount: dropped,
    );
  }

  ScanState _withTransient(
    ScanState s, {
    TextToken? anchor,
    SelectionNotice? notice,
    int droppedCount = 0,
  }) => ScanState(
    step: s.step,
    isBusy: s.isBusy,
    document: s.document,
    selection: s.selection,
    mode: s.mode,
    anchor: anchor,
    notice: notice,
    droppedCount: droppedCount,
    items: s.items,
    deckId: s.deckId,
    strategy: s.strategy,
    image: s.image,
    imageSize: s.imageSize,
    strokes: s.strokes,
    regions: s.regions,
    readStrokes: s.readStrokes,
    failedStrokes: s.failedStrokes,
    manualItems: s.manualItems,
  );

  /// Review items: current text selections (keeping their edits), then the
  /// items without a range.
  List<(SelectedRange?, ScanReviewItem)> _itemsWith(
    List<ScanReviewItem> manual, {
    WordSelection? selection,
  }) {
    final selected = selection ?? state.selection;
    return [
      for (final (range, item) in state.items)
        if (range != null && selected.ranges.contains(range)) (range, item),
      for (final item in manual) (null, item),
    ];
  }

  // ---------------------------------------------------------------------------
  // Review

  /// Opens the review screen with exactly the selected words (and items
  /// read from highlights); nothing else from the page is included.
  void goToReview() {
    final document = state.document;
    if (document == null || state.selectedCount == 0) return;
    final previous = {for (final (range, item) in state.items) ?range: item};
    final items = <(SelectedRange?, ScanReviewItem)>[
      for (final range in state.selection.ranges)
        (
          range,
          previous[range] ??
              () {
                final original = document.selectedText(range);
                return ScanReviewItem(
                  id: ++_lastItemId,
                  original: original,
                  context: document.contextOf(range),
                  hint: LemmaHints.suggest(original),
                );
              }(),
        ),
      for (final item in state.manualItems) (null, item),
    ];
    state = state.copyWith(step: ScanStep.review, items: items);
  }

  void _showReview() => state = state.copyWith(
    step: ScanStep.review,
    items: _itemsWith(state.manualItems),
  );

  /// Back from the review: to the text when there is one, otherwise to the
  /// photo with its highlights.
  void backToSelect() => state = state.copyWith(
    step: state.document != null ? ScanStep.select : ScanStep.highlight,
  );

  void updateItem(ScanReviewItem item) => state = state.copyWith(
    items: [
      for (final (range, existing) in state.items)
        (range, existing.id == item.id ? item : existing),
    ],
    manualItems: [
      for (final existing in state.manualItems)
        existing.id == item.id ? item : existing,
    ],
  );

  /// Removes an item from the review list and deselects it.
  void removeItem(int id) {
    final entry = state.items.where((e) => e.$2.id == id).firstOrNull;
    if (entry == null) return;
    final items = state.items.where((e) => e.$2.id != id).toList();
    final range = entry.$1;
    state = state.copyWith(
      step: items.isEmpty ? _selectionStep() : ScanStep.review,
      items: items,
      selection: range == null ? null : state.selection.remove(range),
      manualItems: [
        for (final item in state.manualItems)
          if (item.id != id) item,
      ],
    );
  }

  ScanStep _selectionStep() =>
      state.document != null ? ScanStep.select : ScanStep.highlight;

  /// Adds an empty item for a word the user types in.
  void addItem() => _replaceItems(state.items.length, 0, [
    ScanReviewItem(id: ++_lastItemId, original: '', context: ''),
  ]);

  /// Replaces item [id] with one item per word of it.
  void splitItem(int id) {
    final index = state.items.indexWhere((e) => e.$2.id == id);
    if (index < 0) return;
    final item = state.items[index].$2;
    final words = item.original
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.replaceAll(
            RegExp(r'^[.,;:!?"„“”»«()]+|[.,;:!?"„“”»«()]+$'),
            '',
          ),
        )
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < 2) return;
    _replaceItems(index, 1, [
      for (final w in words)
        ScanReviewItem(
          id: ++_lastItemId,
          original: w,
          context: item.context,
          hint: LemmaHints.suggest(w),
          stroke: item.stroke,
        ),
    ]);
  }

  /// Joins item [id] with the next one into one expression.
  void combineWithNext(int id) {
    final index = state.items.indexWhere((e) => e.$2.id == id);
    if (index < 0 || index + 1 >= state.items.length) return;
    final a = state.items[index].$2, b = state.items[index + 1].$2;
    final original = '${a.original} ${b.original}'.trim();
    _replaceItems(index, 2, [
      ScanReviewItem(
        id: ++_lastItemId,
        original: original,
        context: a.context == b.context || b.context.isEmpty
            ? a.context
            : '${a.context} ${b.context}'.trim(),
        meaning: [a.meaning, b.meaning].where((m) => m.isNotEmpty).join('; '),
        hint: LemmaHints.suggest(original),
        stroke: a.stroke ?? b.stroke,
      ),
    ]);
  }

  /// Replaces [count] review items at [index] with [replacement]. Replaced
  /// text selections are deselected; all resulting items keep the review
  /// order and become items without a range.
  void _replaceItems(int index, int count, List<ScanReviewItem> replacement) {
    final removed = state.items.sublist(index, index + count);
    var selection = state.selection;
    for (final (range, _) in removed) {
      if (range != null) selection = selection.remove(range);
    }
    final items = [
      ...state.items.sublist(0, index),
      for (final item in replacement) (null, item),
      ...state.items.sublist(index + count),
    ];
    state = state.copyWith(
      items: items,
      selection: selection,
      manualItems: [
        for (final (range, item) in items)
          if (range == null) item,
      ],
    );
  }

  void selectDeck(String deckId) => state = state.copyWith(deckId: deckId);

  void setStrategy(DuplicateStrategy strategy) =>
      state = state.copyWith(strategy: strategy);

  /// Candidates for saving: one per review item with a valid draft.
  List<ImportCandidate> candidates() {
    final deckId = state.deckId;
    if (deckId == null) return const [];
    return [
      for (final (index, (_, item)) in state.items.indexed)
        if (item.toDraft(deckId).validate().isEmpty)
          ImportCandidate(rowNumber: index + 1, draft: item.toDraft(deckId)),
    ];
  }

  /// Saves the reviewed items in one transaction (all or nothing).
  Future<void> save() async {
    final deckId = state.deckId;
    if (deckId == null || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      final summary = await ref
          .read(vocabularyRepositoryProvider)
          .importEntries(deckId, candidates(), state.strategy);
      _discardKept();
      state = ScanState(
        step: ScanStep.done,
        deckId: deckId,
        strategy: state.strategy,
        result: summary,
      );
    } on AppException catch (e) {
      state = ScanState(
        step: ScanStep.review,
        document: state.document,
        selection: state.selection,
        mode: state.mode,
        items: state.items,
        deckId: state.deckId,
        strategy: state.strategy,
        saveError: e,
        image: state.image,
        imageSize: state.imageSize,
        strokes: state.strokes,
        regions: state.regions,
        readStrokes: state.readStrokes,
        failedStrokes: state.failedStrokes,
        manualItems: state.manualItems,
      );
    }
  }

  /// Starts a new scan, keeping the deck and duplicate strategy.
  void reset() => backToCapture();
}

final scanControllerProvider = NotifierProvider.autoDispose
    .family<ScanController, ScanState, String?>(ScanController.new);

/// Duplicate-handling decisions for the review list, keyed by item index + 1.
final scanDecisionsProvider = Provider.autoDispose
    .family<AsyncValue<Map<int, ImportDecision>>, String?>((
      ref,
      initialDeckId,
    ) {
      final controller = ref.watch(
        scanControllerProvider(initialDeckId).notifier,
      );
      final (deckId, _, _) = ref.watch(
        scanControllerProvider(initialDeckId)
            .select((s) => (s.deckId, s.items, s.strategy)),
      );
      if (deckId == null) return const AsyncData({});
      final strategy = ref.read(scanControllerProvider(initialDeckId)).strategy;
      return ref
          .watch(deckEntriesProvider(deckId))
          .whenData(
            (existing) => {
              for (final d in planImport(
                controller.candidates(),
                existing,
                strategy,
              ))
                d.rowNumber: d,
            },
          );
    });
