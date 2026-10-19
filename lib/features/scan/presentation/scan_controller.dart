import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/text_normalizer.dart';
import '../../vocabulary/domain/duplicate_detection.dart';
import '../../vocabulary/domain/vocabulary_repository.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../data/scan_image_source.dart';
import '../domain/lemma_hints.dart';
import '../domain/scan_document.dart';
import '../domain/scan_review_item.dart';
import '../domain/scan_text.dart';
import '../domain/text_tokenizer.dart';
import '../domain/word_selection.dart';

enum ScanStep { capture, typing, select, review, done }

enum SelectionMode { word, expression }

/// How the selection step shows the page: the photo with selectable word
/// boxes, or the recognized text.
enum ScanView { image, text }

/// Short-lived messages for the selection screen.
enum SelectionNotice {
  pickExpressionEnd,
  expressionTooLong,
  selectionsDropped,

  /// No text was found in a drawn area.
  regionEmpty,

  /// Reading a drawn area failed.
  regionFailed,
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
    this.view = ScanView.text,
    this.manualItems = const [],
    this.regionBusy = false,
    this.regionText,
  });

  final ScanStep step;

  /// Picking an image, recognizing text or saving.
  final bool isBusy;

  /// Problem while picking or recognizing (capture step).
  final Object? error;

  final ScanDocument? document;
  final WordSelection selection;
  final SelectionMode mode;

  /// First word of an expression being selected.
  final TextToken? anchor;
  final SelectionNotice? notice;
  final int droppedCount;

  /// Items on the review screen: selections in text order with their
  /// ranges, then items read from drawn areas (no range).
  final List<(SelectedRange?, ScanReviewItem)> items;
  final String? deckId;
  final DuplicateStrategy strategy;
  final ImportSummary? result;
  final Object? saveError;

  /// The page photo, kept only while this scan is open and only when words
  /// can be selected on it. Deleted when the scan ends.
  final PickedImage? image;
  final ScanView view;

  /// Words read from areas drawn on the photo and confirmed by the user.
  final List<ScanReviewItem> manualItems;

  /// A drawn area is being read.
  final bool regionBusy;

  /// Text read from a drawn area, waiting for the user to correct and add
  /// it (or dismiss it).
  final String? regionText;

  /// Everything that will go to the review screen.
  int get selectedCount => selection.length + manualItems.length;

  bool get canShowImage =>
      image != null && (document?.scanText.hasLayout ?? false);

  ScanState copyWith({
    ScanStep? step,
    bool? isBusy,
    ScanDocument? document,
    WordSelection? selection,
    SelectionMode? mode,
    List<(SelectedRange?, ScanReviewItem)>? items,
    String? deckId,
    DuplicateStrategy? strategy,
    ScanView? view,
    List<ScanReviewItem>? manualItems,
    bool regionBusy = false,
  }) => ScanState(
    step: step ?? this.step,
    isBusy: isBusy ?? this.isBusy,
    document: document ?? this.document,
    selection: selection ?? this.selection,
    mode: mode ?? this.mode,
    // Transient fields (anchor, notice, errors, region result) are cleared
    // by default.
    anchor: null,
    items: items ?? this.items,
    deckId: deckId ?? this.deckId,
    strategy: strategy ?? this.strategy,
    result: result,
    image: image,
    view: view ?? this.view,
    manualItems: manualItems ?? this.manualItems,
    regionBusy: regionBusy,
  );
}

class ScanController extends Notifier<ScanState> {
  ScanController(this.initialDeckId);

  final String? initialDeckId;
  bool _recoveryChecked = false;
  late ScanImageSource _source;

  /// The photo kept for selecting on it; see [ScanState.image].
  PickedImage? _kept;
  int _lastItemId = 0;

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
    if (image != null) await _recognize(image);
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
      await _recognize(image);
    } on AppException catch (e) {
      _fail(e);
    }
  }

  Future<void> _recognize(PickedImage image) async {
    state = state.copyWith(isBusy: true);
    var keep = false;
    try {
      validatePickedImage(image);
      final engine = ref.read(textRecognitionEngineProvider);
      if (!engine.isAvailable) {
        throw const ScanException(ScanError.ocrUnavailable);
      }
      final text = await engine.recognize(image);
      // The photo is kept only to select words on it, until the scan ends.
      keep = text.hasLayout && ref.mounted;
      if (keep) {
        _discardKept();
        _kept = image;
      }
      _open(text, image: keep ? image : null);
    } on AppException catch (e) {
      _fail(e);
    } finally {
      if (!keep) await _source.discard(image);
    }
  }

  void _fail(Object error) => state = ScanState(
    deckId: state.deckId,
    strategy: state.strategy,
    error: error,
  );

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

  void _open(ScanText text, {PickedImage? image}) => state = ScanState(
    step: ScanStep.select,
    document: ScanDocument(text),
    deckId: state.deckId,
    strategy: state.strategy,
    image: image,
    view: image != null ? ScanView.image : ScanView.text,
  );

  void backToCapture() {
    _discardKept();
    state = ScanState(deckId: state.deckId, strategy: state.strategy);
  }

  /// Switches between the photo and the recognized text; selections are
  /// shared by both.
  void setView(ScanView view) {
    if (view == ScanView.image && !state.canShowImage) return;
    state = state.copyWith(view: view);
  }

  // ---------------------------------------------------------------------------
  // Selection

  void setMode(SelectionMode mode) => state = state.copyWith(mode: mode);

  void clearSelection() => state = state.copyWith(
    selection: const WordSelection(),
    items: const [],
    manualItems: const [],
  );

  /// Selects or deselects one word (photo view: a tap on a word).
  void toggleWord(TextToken word) {
    final document = state.document;
    if (document == null || !word.isWord) return;
    state = state.copyWith(
      selection: state.selection.toggle(document.rangeOfWord(word)),
    );
  }

  /// Selects the words from [from] to [to] in reading order as one
  /// expression (photo view: touch, hold and drag). Refused with a notice
  /// across paragraphs or beyond the expression length limit.
  bool selectBetween(TextToken from, TextToken to) {
    final document = state.document;
    if (document == null || !from.isWord || !to.isWord) return false;
    final range = from.start == to.start
        ? document.rangeOfWord(from)
        : document.rangeBetween(
            from,
            to,
            maxWords: AppConfig.maxExpressionWords,
          );
    if (range == null) {
      state = _withTransient(
        state.copyWith(),
        notice: SelectionNotice.expressionTooLong,
      );
      return false;
    }
    state = state.copyWith(selection: state.selection.add(range));
    return true;
  }

  /// Deselects [range].
  void removeRange(SelectedRange range) =>
      state = state.copyWith(selection: state.selection.remove(range));

  /// Replaces an expression with its single words.
  void splitRange(SelectedRange range) {
    final document = state.document;
    if (document == null) return;
    var selection = state.selection.remove(range);
    for (final word in document.words) {
      if (word.start >= range.start && word.end <= range.end) {
        selection = selection.add(document.rangeOfWord(word));
      }
    }
    state = state.copyWith(selection: selection);
  }

  // ---------------------------------------------------------------------------
  // Drawn areas (fallback when words are not recognized well)

  /// Crops [imageRect] (pixels of the photo) and recognizes it again on the
  /// device. The result is offered in [ScanState.regionText] for
  /// correction; nothing is selected until the user adds it.
  Future<void> recognizeRegion(Rect imageRect) async {
    final image = state.image;
    if (image == null || state.regionBusy || imageRect.isEmpty) return;
    state = state.copyWith(regionBusy: true);
    PickedImage? crop;
    try {
      crop = await ref.read(imageCropperProvider).crop(image, imageRect);
      final text = await ref
          .read(textRecognitionEngineProvider)
          .recognize(crop);
      if (!ref.mounted) return;
      final document = ScanDocument(text);
      final found = TextNormalizer.collapseWhitespace(
        document.tokens.map((t) => t.display).join(),
      ).trim();
      state = found.isEmpty
          ? _withTransient(
              state.copyWith(),
              notice: SelectionNotice.regionEmpty,
            )
          : _withTransient(state.copyWith(), regionText: found);
    } on AppException {
      if (!ref.mounted) return;
      state = _withTransient(
        state.copyWith(),
        notice: SelectionNotice.regionFailed,
      );
    } finally {
      if (crop != null) await _source.discard(crop);
    }
  }

  /// Adds the (corrected) text of a drawn area as one item.
  void addRegionText(String text, {String context = ''}) {
    final original = TextNormalizer.collapseWhitespace(text).trim();
    if (original.isEmpty) return dismissRegionText();
    state = state.copyWith(
      manualItems: [
        ...state.manualItems,
        ScanReviewItem(
          id: ++_lastItemId,
          original: original,
          context: context.trim() == original ? '' : context.trim(),
          hint: LemmaHints.suggest(original),
        ),
      ],
    );
  }

  void dismissRegionText() => state = state.copyWith();

  void removeManualItem(int id) => state = state.copyWith(
    manualItems: [
      for (final item in state.manualItems)
        if (item.id != id) item,
    ],
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
        items: const [],
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
    String? regionText,
  }) => ScanState(
    step: s.step,
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
    view: s.view,
    manualItems: s.manualItems,
    regionText: regionText,
  );

  // ---------------------------------------------------------------------------
  // Review

  /// Opens the review screen with exactly the selected words (and words
  /// read from drawn areas); nothing else from the page is included.
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

  void backToSelect() => state = state.copyWith(step: ScanStep.select);

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
      step: items.isEmpty ? ScanStep.select : ScanStep.review,
      items: items,
      selection: range == null ? null : state.selection.remove(range),
      manualItems: [
        for (final item in state.manualItems)
          if (item.id != id) item,
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
        view: state.view,
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
