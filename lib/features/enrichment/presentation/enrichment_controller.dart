import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/text_normalizer.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../data/ai_local_store.dart';
import '../domain/enrichment.dart';
import '../domain/enrichment_plan.dart';
import 'free_usage_controller.dart';

/// Which entries a session enriches.
@immutable
class EnrichmentTarget {
  /// The deck's entries without meanings (an interrupted run resumes).
  const EnrichmentTarget.deck(String this.deckId)
    : entryId = null,
      entryIds = const [];

  /// One entry, on request, even if it already has meanings.
  const EnrichmentTarget.entry(String this.deckId, String this.entryId)
    : entryIds = const [];

  /// Entries the user selected in a word list (from any deck). Only those
  /// without a meaning are sent, and only meanings are requested.
  const EnrichmentTarget.selection(this.entryIds)
    : deckId = null,
      entryId = null;

  final String? deckId;
  final String? entryId;

  /// In list order; used by [EnrichmentTarget.selection] only.
  final List<String> entryIds;

  bool get isSelection => deckId == null;

  /// A deck run is remembered until saved, so it can be resumed.
  bool get isResumable => deckId != null && entryId == null;

  EnrichmentScope get scope =>
      isSelection ? EnrichmentScope.meanings : EnrichmentScope.full;

  @override
  bool operator ==(Object other) =>
      other is EnrichmentTarget &&
      other.deckId == deckId &&
      other.entryId == entryId &&
      listEquals(other.entryIds, entryIds);

  @override
  int get hashCode => Object.hash(deckId, entryId, Object.hashAll(entryIds));
}

/// Entry ids that a running session is requesting right now. Two sessions
/// (e.g. a deck run and a selection) never send the same word at the same
/// time: the second one marks it [EnrichmentError.busy] instead.
class EnrichmentJobRegistry {
  final _busy = <String>{};

  /// Claims every id in [ids] that no other session holds; returns those.
  Set<String> claim(Iterable<String> ids) => {
    for (final id in ids)
      if (_busy.add(id)) id,
  };

  void release(Iterable<String> ids) => _busy.removeAll(ids);

  bool isBusy(String id) => _busy.contains(id);
}

final enrichmentJobRegistryProvider = Provider<EnrichmentJobRegistry>(
  (ref) => EnrichmentJobRegistry(),
);

enum EnrichmentPhase {
  /// Waiting for the user to start (nothing has been sent).
  ready,

  /// No API key is saved; nothing can be sent.
  notConfigured,

  /// Nothing to enrich.
  empty,
  running,
  review,
  saving,
  done,
}

enum ItemStatus { queued, running, proposed, failed, skipped }

@immutable
class EnrichmentItem {
  const EnrichmentItem({
    required this.entry,
    this.status = ItemStatus.queued,
    this.plan,
    this.error,
    this.meanings = const {},
    this.fields = const {},
    this.edits = const {},
  });

  final VocabularyEntry entry;
  final ItemStatus status;
  final EnrichmentPlan? plan;
  final Object? error;

  /// The user's selection (indices into `plan.newMeanings`).
  final Set<int> meanings;
  final Set<EnrichmentField> fields;

  /// The user's corrections of suggested meanings (index → text).
  final Map<int, String> edits;

  bool get hasSelection => meanings.isNotEmpty || fields.isNotEmpty;

  /// The text of suggested meaning [index] as it would be saved.
  String meaningText(int index) =>
      edits[index] ?? plan!.newMeanings[index].text;

  EnrichmentItem copyWith({
    ItemStatus? status,
    EnrichmentPlan? plan,
    Object? Function()? error,
    Set<int>? meanings,
    Set<EnrichmentField>? fields,
    Map<int, String>? edits,
  }) => EnrichmentItem(
    entry: entry,
    status: status ?? this.status,
    plan: plan ?? this.plan,
    error: error != null ? error() : this.error,
    meanings: meanings ?? this.meanings,
    fields: fields ?? this.fields,
    edits: edits ?? this.edits,
  );
}

@immutable
class EnrichmentState {
  const EnrichmentState({
    required this.phase,
    this.items = const [],
    this.stopError,
    this.saveError,
    this.savedCount = 0,
    this.costUsd,
    this.resumedCount,
    this.freeOnly = true,
    this.excludedCount = 0,
    this.overflowCount = 0,
  });

  final EnrichmentPhase phase;
  final List<EnrichmentItem> items;

  /// A failure that stopped the whole run (invalid key, no credits).
  final Object? stopError;
  final Object? saveError;
  final int savedCount;

  /// Sum of the costs OpenRouter reported for this session's requests;
  /// null when none was reported.
  final double? costUsd;

  /// Words left from an unfinished earlier run that this session resumes;
  /// null for a new run.
  final int? resumedCount;

  /// Free-only mode was on when the session was loaded.
  final bool freeOnly;

  /// Selected words left out because they already have a meaning.
  final int excludedCount;

  /// Selected words without a meaning beyond [AppConfig.aiMaxBatchSize],
  /// left for a later run.
  final int overflowCount;

  /// The run stopped for a reason that may pass by itself (an account
  /// rate limit), so retrying later makes sense.
  bool get canRetryAfterStop =>
      stopError is EnrichmentException &&
      (stopError! as EnrichmentException).error == EnrichmentError.rateLimited;

  int get doneCount => items
      .where(
        (i) => i.status != ItemStatus.queued && i.status != ItemStatus.running,
      )
      .length;

  int get selectedCount => items.where((i) => i.hasSelection).length;

  /// Words answered (with or without new suggestions).
  int get succeededCount => items
      .where(
        (i) =>
            i.status == ItemStatus.proposed || i.status == ItemStatus.skipped,
      )
      .length;

  int get failedCount =>
      items.where((i) => i.status == ItemStatus.failed).length;

  bool get hasFailures => items.any((i) => i.status == ItemStatus.failed);

  EnrichmentState copyWith({
    EnrichmentPhase? phase,
    List<EnrichmentItem>? items,
    Object? Function()? stopError,
    Object? Function()? saveError,
    int? savedCount,
    double? Function()? costUsd,
  }) => EnrichmentState(
    phase: phase ?? this.phase,
    items: items ?? this.items,
    stopError: stopError != null ? stopError() : this.stopError,
    saveError: saveError != null ? saveError() : this.saveError,
    savedCount: savedCount ?? this.savedCount,
    costUsd: costUsd != null ? costUsd() : this.costUsd,
    resumedCount: resumedCount,
    freeOnly: freeOnly,
    excludedCount: excludedCount,
    overflowCount: overflowCount,
  );
}

class EnrichmentController extends Notifier<EnrichmentState> {
  EnrichmentController(this.target);

  final EnrichmentTarget target;
  EnrichmentCancellation? _cancellation;

  /// Ids this session holds in [EnrichmentJobRegistry] while running.
  Set<String>? _claimed;

  @override
  EnrichmentState build() {
    final registry = ref.read(enrichmentJobRegistryProvider);
    ref.onDispose(() {
      _cancellation?.cancel();
      if (_claimed case final ids?) registry.release(ids);
    });
    Future.microtask(_load);
    return const EnrichmentState(phase: EnrichmentPhase.ready);
  }

  AiLocalState get _local => ref.read(aiLocalStateProvider);

  Future<void> _load() async {
    final repository = ref.read(vocabularyRepositoryProvider);
    final List<VocabularyEntry> entries;
    int? resumed;
    var excluded = 0;
    var overflow = 0;
    if (target.isSelection) {
      final selected = <VocabularyEntry>[];
      for (final id in target.entryIds.toSet()) {
        if (await repository.getEntry(id) case final entry?) {
          selected.add(entry);
        }
      }
      final eligible = selectionCandidates(selected);
      excluded = selected.length - eligible.length;
      entries = eligible.take(AppConfig.aiMaxBatchSize).toList();
      overflow = eligible.length - entries.length;
    } else if (target.entryId case final id?) {
      final entry = await repository.getEntry(id);
      entries = entry == null ? const [] : [entry];
    } else {
      final deckId = target.deckId!;
      final all = await repository.getEntries(deckId);
      // An unfinished earlier run continues with its own words; those
      // already saved (or deleted) are no longer candidates.
      final job = await _quietly(() => _local.readJob(deckId));
      final pending = job == null
          ? const <VocabularyEntry>[]
          : batchCandidates([
              for (final e in all)
                if (job.contains(e.id)) e,
            ]);
      if (pending.isNotEmpty) {
        entries = pending;
        resumed = pending.length;
      } else {
        if (job != null) await _quietly(() => _local.clearJob(deckId));
        entries = batchCandidates(all);
      }
    }
    final key = await ref.read(aiSettingsStoreProvider).readApiKey();
    final prefs =
        await _quietly(_local.readPreferences) ?? const AiPreferences();
    if (!ref.mounted) return;
    state = EnrichmentState(
      phase: key == null || key.trim().isEmpty
          ? EnrichmentPhase.notConfigured
          : entries.isEmpty
          ? EnrichmentPhase.empty
          : EnrichmentPhase.ready,
      items: [for (final e in entries) EnrichmentItem(entry: e)],
      resumedCount: resumed,
      freeOnly: prefs.freeOnly,
      excludedCount: excluded,
      overflowCount: overflow,
    );
  }

  /// Local bookkeeping (jobs, preferences) never blocks enrichment.
  static Future<T?> _quietly<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on StorageException {
      return null;
    }
  }

  /// Re-checks the key, e.g. after returning from the settings screen.
  Future<void> reload() => _load();

  /// Sends the queued items in batches (one request per batch, one request
  /// at a time). A batch holds at most the configured number of words and
  /// at most [AppConfig.aiMaxBatchInputChars] characters of input. Words
  /// already answered come from the cache without a request; a failed batch
  /// or word does not affect the words already answered.
  ///
  /// A batch whose answer is unusable as a whole (invalid JSON, cut off) is
  /// sent once more as two smaller batches: the model did answer, so
  /// nothing is ambiguous, and a smaller answer is more likely to be
  /// complete. Timeouts and network errors are never re-sent automatically.
  Future<void> start() async {
    if (state.phase != EnrichmentPhase.ready &&
        state.phase != EnrichmentPhase.review) {
      return;
    }
    final cancellation = _cancellation = EnrichmentCancellation();
    final registry = ref.read(enrichmentJobRegistryProvider);
    final claimed = _claimed = registry.claim([
      for (final item in state.items)
        if (item.status == ItemStatus.queued) item.entry.id,
    ]);
    state = state.copyWith(
      phase: EnrichmentPhase.running,
      stopError: () => null,
      saveError: () => null,
      items: [
        for (final item in state.items)
          item.status == ItemStatus.queued && !claimed.contains(item.entry.id)
              ? item.copyWith(
                  status: ItemStatus.failed,
                  error: () => const EnrichmentException(EnrichmentError.busy),
                )
              : item,
      ],
    );
    try {
      await _run(cancellation);
    } finally {
      registry.release(claimed);
      if (identical(_claimed, claimed)) _claimed = null;
    }
  }

  Future<void> _run(EnrichmentCancellation cancellation) async {
    final service = ref.read(enrichmentServiceProvider);
    final prefs =
        await _quietly(_local.readPreferences) ?? const AiPreferences();
    if (target.isResumable) {
      // Remembered until saved, so an interrupted run can be resumed.
      await _quietly(
        () => _local.writeJob(target.deckId!, [
          for (final item in state.items)
            if (item.status != ItemStatus.skipped) item.entry.id,
        ]),
      );
    }

    var maxWords = prefs.wordsPerRequest;
    // Words already re-sent in a smaller batch during this run.
    final split = <String>{};
    while (ref.mounted && !cancellation.isCancelled) {
      final queued = [
        for (var i = 0; i < state.items.length; i++)
          if (state.items[i].status == ItemStatus.queued) i,
      ];
      if (queued.isEmpty) break;
      final requests = {
        for (final i in queued)
          i: requestFor(state.items[i].entry, scope: target.scope),
      };
      final chunk = queued
          .take(
            nextBatchLength([
              for (final i in queued) requestSize(requests[i]!),
            ], maxWords: maxWords),
          )
          .toList();
      for (final i in chunk) {
        _update(i, state.items[i].copyWith(status: ItemStatus.running));
      }
      try {
        final outcomes = await service.enrichBatch([
          for (final i in chunk) requests[i]!,
        ], cancellation: cancellation);
        if (!ref.mounted) return;
        for (final (n, i) in chunk.indexed) {
          _apply(i, outcomes[n]);
        }
      } on EnrichmentException catch (e) {
        if (!ref.mounted) return;
        if (e.error == EnrichmentError.cancelled) {
          for (final i in chunk) {
            _update(i, state.items[i].copyWith(status: ItemStatus.queued));
          }
          break;
        }
        final ids = [for (final i in chunk) state.items[i].entry.id];
        if (e.error == EnrichmentError.malformedResponse &&
            chunk.length > 1 &&
            !ids.any(split.contains)) {
          split.addAll(ids);
          maxWords = chunk.length ~/ 2;
          for (final i in chunk) {
            _update(i, state.items[i].copyWith(status: ItemStatus.queued));
          }
          continue;
        }
        for (final i in chunk) {
          _update(
            i,
            state.items[i].copyWith(status: ItemStatus.failed, error: () => e),
          );
        }
        if (_stopsRun(e)) {
          state = state.copyWith(stopError: () => e);
          break;
        }
      }
    }
    if (!ref.mounted) return;
    _cancellation = null;
    state = state.copyWith(phase: EnrichmentPhase.review);
    if (ref.exists(freeUsageControllerProvider)) {
      ref.invalidate(freeUsageControllerProvider);
    }
  }

  /// Failures that affect every further request: stop instead of failing
  /// (or re-sending) each one. An account-level rate limit stops too, so
  /// the limit is never worked around; a provider's own limit does not.
  static bool _stopsRun(EnrichmentException e) => switch (e.error) {
    EnrichmentError.notConfigured ||
    EnrichmentError.invalidKey ||
    EnrichmentError.insufficientCredits ||
    EnrichmentError.dailyQuotaExhausted ||
    EnrichmentError.paidModelBlocked => true,
    EnrichmentError.rateLimited => !e.upstream,
    _ => false,
  };

  void _apply(int index, EnrichmentOutcome outcome) {
    final item = state.items[index];
    switch (outcome) {
      case EnrichmentSucceeded(:final proposal):
        final plan = EnrichmentPlan.build(item.entry, proposal);
        _update(
          index,
          item.copyWith(
            status: plan.hasSuggestions
                ? ItemStatus.proposed
                : ItemStatus.skipped,
            plan: plan,
            error: () => null,
            meanings: plan.defaultMeanings,
            fields: plan.defaultFields,
            edits: const {},
          ),
        );
        if (proposal.costUsd case final cost?) {
          state = state.copyWith(costUsd: () => (state.costUsd ?? 0) + cost);
        }
      case EnrichmentFailed(:final error):
        _update(
          index,
          item.copyWith(status: ItemStatus.failed, error: () => error),
        );
    }
  }

  void cancel() => _cancellation?.cancel();

  /// Queues failed (and unfinished) items again and restarts.
  Future<void> retry() async {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          item.status == ItemStatus.failed
              ? item.copyWith(status: ItemStatus.queued, error: () => null)
              : item,
      ],
    );
    await start();
  }

  void toggleMeaning(int item, int meaning) {
    final current = state.items[item];
    final selection = {...current.meanings};
    selection.contains(meaning)
        ? selection.remove(meaning)
        : selection.add(meaning);
    _update(item, current.copyWith(meanings: selection));
  }

  /// Replaces suggested meaning [meaning] of item [item] with the user's
  /// correction and selects it. Returns false, changing nothing, for blank
  /// or too long text.
  bool editMeaning(int item, int meaning, String text) {
    final current = state.items[item];
    final suggested = current.plan?.newMeanings.elementAtOrNull(meaning);
    final cleaned = TextNormalizer.collapseWhitespace(text);
    if (suggested == null ||
        cleaned.isEmpty ||
        cleaned.runes.length > AppConfig.maxMeaningLength) {
      return false;
    }
    final edits = {...current.edits};
    if (cleaned == suggested.text) {
      edits.remove(meaning);
    } else {
      edits[meaning] = cleaned;
    }
    _update(
      item,
      current.copyWith(edits: edits, meanings: {...current.meanings, meaning}),
    );
    return true;
  }

  void toggleField(int item, EnrichmentField field) {
    final current = state.items[item];
    final selection = {...current.fields};
    selection.contains(field) ? selection.remove(field) : selection.add(field);
    _update(item, current.copyWith(fields: selection));
  }

  /// Saves every item with a selection in one transaction.
  Future<void> save() async {
    final updates = [
      for (final item in state.items)
        ?item.plan?.toUpdate(
          meanings: item.meanings,
          fields: item.fields,
          edits: item.edits,
        ),
    ];
    if (updates.isEmpty) return;
    state = state.copyWith(
      phase: EnrichmentPhase.saving,
      saveError: () => null,
    );
    try {
      await ref.read(vocabularyRepositoryProvider).applyEnrichments(updates);
      if (target.isResumable &&
          !state.items.any(
            (i) =>
                i.status == ItemStatus.failed || i.status == ItemStatus.queued,
          )) {
        // Every word of the run is finished.
        await _quietly(() => _local.clearJob(target.deckId!));
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: EnrichmentPhase.done,
        savedCount: updates.length,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: EnrichmentPhase.review, saveError: () => e);
    }
  }

  void _update(int index, EnrichmentItem item) {
    final items = [...state.items];
    items[index] = item;
    state = state.copyWith(items: items);
  }
}

final enrichmentControllerProvider = NotifierProvider.autoDispose
    .family<EnrichmentController, EnrichmentState, EnrichmentTarget>(
      EnrichmentController.new,
    );
