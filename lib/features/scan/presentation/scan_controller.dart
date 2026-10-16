import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
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

/// Short-lived messages for the selection screen.
enum SelectionNotice { pickExpressionEnd, expressionTooLong, selectionsDropped }

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

  /// Items on the review screen, in text order, with their ranges.
  final List<(SelectedRange, ScanReviewItem)> items;
  final String? deckId;
  final DuplicateStrategy strategy;
  final ImportSummary? result;
  final Object? saveError;

  ScanState copyWith({
    ScanStep? step,
    bool? isBusy,
    ScanDocument? document,
    WordSelection? selection,
    SelectionMode? mode,
    List<(SelectedRange, ScanReviewItem)>? items,
    String? deckId,
    DuplicateStrategy? strategy,
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
  );
}

class ScanController extends Notifier<ScanState> {
  ScanController(this.initialDeckId);

  final String? initialDeckId;
  bool _recoveryChecked = false;

  @override
  ScanState build() => ScanState(deckId: initialDeckId);

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
    final source = ref.read(scanImageSourceProvider);
    state = state.copyWith(isBusy: true);
    try {
      validatePickedImage(image);
      final engine = ref.read(textRecognitionEngineProvider);
      if (!engine.isAvailable) {
        throw const ScanException(ScanError.ocrUnavailable);
      }
      final text = await engine.recognize(image);
      _open(text);
    } on AppException catch (e) {
      _fail(e);
    } finally {
      // The page photo is never kept.
      await source.discard(image);
    }
  }

  void _fail(Object error) => state = ScanState(
    deckId: state.deckId,
    strategy: state.strategy,
    error: error,
  );

  void startTyping() => state = ScanState(
    step: ScanStep.typing,
    deckId: state.deckId,
    strategy: state.strategy,
  );

  /// Uses typed or pasted text instead of OCR.
  void useTypedText(String input) {
    final text = ScanText.typed(input);
    if (text.isBlank) return;
    _open(text);
  }

  void _open(ScanText text) => state = ScanState(
    step: ScanStep.select,
    document: ScanDocument(text),
    deckId: state.deckId,
    strategy: state.strategy,
  );

  void backToCapture() =>
      state = ScanState(deckId: state.deckId, strategy: state.strategy);

  // ---------------------------------------------------------------------------
  // Selection

  void setMode(SelectionMode mode) => state = state.copyWith(mode: mode);

  void clearSelection() =>
      state = state.copyWith(selection: const WordSelection(), items: const []);

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
  );

  // ---------------------------------------------------------------------------
  // Review

  void goToReview() {
    final document = state.document;
    if (document == null || state.selection.isEmpty) return;
    final previous = {for (final (range, item) in state.items) range: item};
    var nextId = state.items.fold(0, (max, e) => e.$2.id > max ? e.$2.id : max);
    final items = [
      for (final range in state.selection.ranges)
        (
          range,
          previous[range] ??
              () {
                final original = document.selectedText(range);
                return ScanReviewItem(
                  id: ++nextId,
                  original: original,
                  context: document.contextOf(range),
                  hint: LemmaHints.suggest(original),
                );
              }(),
        ),
    ];
    state = state.copyWith(step: ScanStep.review, items: items);
  }

  void backToSelect() => state = state.copyWith(step: ScanStep.select);

  void updateItem(ScanReviewItem item) => state = state.copyWith(
    items: [
      for (final (range, existing) in state.items)
        (range, existing.id == item.id ? item : existing),
    ],
  );

  /// Removes an item from the review list and deselects it.
  void removeItem(int id) {
    final entry = state.items.where((e) => e.$2.id == id).firstOrNull;
    if (entry == null) return;
    final items = state.items.where((e) => e.$2.id != id).toList();
    state = state.copyWith(
      step: items.isEmpty ? ScanStep.select : ScanStep.review,
      items: items,
      selection: state.selection.remove(entry.$1),
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
