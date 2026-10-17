import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../domain/enrichment.dart';
import '../domain/enrichment_plan.dart';

/// Which entries a session enriches: one entry (on request, even if it
/// already has meanings) or the deck's entries without meanings.
typedef EnrichmentTarget = ({String deckId, String? entryId});

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
  });

  final VocabularyEntry entry;
  final ItemStatus status;
  final EnrichmentPlan? plan;
  final Object? error;

  /// The user's selection (indices into `plan.newMeanings`).
  final Set<int> meanings;
  final Set<EnrichmentField> fields;

  bool get hasSelection => meanings.isNotEmpty || fields.isNotEmpty;

  EnrichmentItem copyWith({
    ItemStatus? status,
    EnrichmentPlan? plan,
    Object? Function()? error,
    Set<int>? meanings,
    Set<EnrichmentField>? fields,
  }) => EnrichmentItem(
    entry: entry,
    status: status ?? this.status,
    plan: plan ?? this.plan,
    error: error != null ? error() : this.error,
    meanings: meanings ?? this.meanings,
    fields: fields ?? this.fields,
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

  int get doneCount => items
      .where(
        (i) => i.status != ItemStatus.queued && i.status != ItemStatus.running,
      )
      .length;

  int get selectedCount => items.where((i) => i.hasSelection).length;

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
  );
}

class EnrichmentController extends Notifier<EnrichmentState> {
  EnrichmentController(this.target);

  final EnrichmentTarget target;
  EnrichmentCancellation? _cancellation;

  @override
  EnrichmentState build() {
    ref.onDispose(() => _cancellation?.cancel());
    Future.microtask(_load);
    return const EnrichmentState(phase: EnrichmentPhase.ready);
  }

  Future<void> _load() async {
    final repository = ref.read(vocabularyRepositoryProvider);
    final List<VocabularyEntry> entries;
    if (target.entryId case final id?) {
      final entry = await repository.getEntry(id);
      entries = entry == null ? const [] : [entry];
    } else {
      entries = batchCandidates(await repository.getEntries(target.deckId));
    }
    final key = await ref.read(aiSettingsStoreProvider).readApiKey();
    if (!ref.mounted) return;
    state = EnrichmentState(
      phase: key == null || key.trim().isEmpty
          ? EnrichmentPhase.notConfigured
          : entries.isEmpty
          ? EnrichmentPhase.empty
          : EnrichmentPhase.ready,
      items: [for (final e in entries) EnrichmentItem(entry: e)],
    );
  }

  /// Re-checks the key, e.g. after returning from the settings screen.
  Future<void> reload() => _load();

  /// Sends one request per queued item, one at a time.
  Future<void> start() async {
    if (state.phase != EnrichmentPhase.ready &&
        state.phase != EnrichmentPhase.review) {
      return;
    }
    final cancellation = _cancellation = EnrichmentCancellation();
    state = state.copyWith(
      phase: EnrichmentPhase.running,
      stopError: () => null,
      saveError: () => null,
    );
    final service = ref.read(enrichmentServiceProvider);

    for (var i = 0; i < state.items.length; i++) {
      if (!ref.mounted) return;
      if (cancellation.isCancelled) break;
      final item = state.items[i];
      if (item.status != ItemStatus.queued) continue;
      _update(i, item.copyWith(status: ItemStatus.running));
      try {
        final proposal = await service.enrich(
          requestFor(item.entry),
          cancellation: cancellation,
        );
        if (!ref.mounted) return;
        final plan = EnrichmentPlan.build(item.entry, proposal);
        _update(
          i,
          item.copyWith(
            status: plan.hasSuggestions
                ? ItemStatus.proposed
                : ItemStatus.skipped,
            plan: plan,
            error: () => null,
            meanings: plan.defaultMeanings,
            fields: plan.defaultFields,
          ),
        );
        if (proposal.costUsd case final cost?) {
          state = state.copyWith(costUsd: () => (state.costUsd ?? 0) + cost);
        }
      } on EnrichmentException catch (e) {
        if (!ref.mounted) return;
        if (e.error == EnrichmentError.cancelled) {
          _update(i, item.copyWith(status: ItemStatus.queued));
          break;
        }
        _update(i, item.copyWith(status: ItemStatus.failed, error: () => e));
        // These affect every request: stop instead of failing each one.
        if (const {
          EnrichmentError.notConfigured,
          EnrichmentError.invalidKey,
          EnrichmentError.insufficientCredits,
        }.contains(e.error)) {
          state = state.copyWith(stopError: () => e);
          break;
        }
      }
    }
    if (!ref.mounted) return;
    _cancellation = null;
    state = state.copyWith(phase: EnrichmentPhase.review);
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
        ?item.plan?.toUpdate(meanings: item.meanings, fields: item.fields),
    ];
    if (updates.isEmpty) return;
    state = state.copyWith(
      phase: EnrichmentPhase.saving,
      saveError: () => null,
    );
    try {
      await ref.read(vocabularyRepositoryProvider).applyEnrichments(updates);
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
