import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../decks/presentation/decks_screen.dart';
import '../domain/duplicate_detection.dart';
import '../domain/vocabulary_draft.dart';
import '../domain/vocabulary_entry.dart';
import 'duplicate_dialog.dart';
import 'vocabulary_providers.dart';

/// Create (when [entryId] is null) or edit a vocabulary entry.
///
/// German fields are always left-to-right and Persian fields right-to-left,
/// regardless of the UI direction.
class VocabularyFormScreen extends ConsumerWidget {
  const VocabularyFormScreen({super.key, this.deckId, this.entryId});

  /// Preselected deck for new entries.
  final String? deckId;

  /// Entry to edit.
  final String? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = entryId;
    if (id == null) {
      return _FormScaffold(
        title: l10n.formNewEntryTitle,
        child: _DeckGate(initialDeckId: deckId),
      );
    }
    final entry = ref.watch(entryProvider(id));
    return _FormScaffold(
      title: l10n.formEditEntryTitle,
      child: switch (entry) {
        AsyncData(value: final e?) => _VocabularyForm(
          key: ValueKey(e.id),
          initialDeckId: e.deckId,
          existing: e,
        ),
        AsyncData() => EmptyStateView(
          icon: Icons.search_off,
          title: l10n.entryNotFound,
        ),
        AsyncError(:final error) => ErrorStateView(error: error),
        _ => const LoadingView(),
      },
    );
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: child,
  );
}

/// Requires at least one deck before showing the form.
class _DeckGate extends ConsumerWidget {
  const _DeckGate({this.initialDeckId});

  final String? initialDeckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(deckSummariesProvider)) {
      AsyncData(:final value) when value.isEmpty => EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: l10n.formNoDecks,
        action: FilledButton.icon(
          onPressed: () => createDeckAndAnnounce(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.actionCreateDeck),
        ),
      ),
      AsyncData(:final value) => _VocabularyForm(
        initialDeckId: value.any((s) => s.deck.id == initialDeckId)
            ? initialDeckId!
            : value.first.deck.id,
      ),
      AsyncError(:final error) => ErrorStateView(
        error: error,
        onRetry: () => ref.invalidate(deckSummariesProvider),
      ),
      _ => const LoadingView(),
    };
  }
}

class _VocabularyForm extends ConsumerStatefulWidget {
  const _VocabularyForm({
    super.key,
    required this.initialDeckId,
    this.existing,
  });

  final String initialDeckId;
  final VocabularyEntry? existing;

  @override
  ConsumerState<_VocabularyForm> createState() => _VocabularyFormState();
}

class _VocabularyFormState extends ConsumerState<_VocabularyForm> {
  final _formKey = GlobalKey<FormState>();
  final _wordFocus = FocusNode();
  late String _deckId = widget.initialDeckId;
  late final _word = TextEditingController(text: widget.existing?.original);
  late final List<TextEditingController> _meanings = [
    for (final m in widget.existing?.meanings ?? const <VocabularyMeaning>[])
      TextEditingController(text: m.text),
    if (widget.existing?.meanings.isEmpty ?? true) TextEditingController(),
  ];
  late final _lemma = TextEditingController(text: widget.existing?.lemma);
  late final _partOfSpeech = TextEditingController(
    text: widget.existing?.partOfSpeech,
  );
  late final _example = TextEditingController(
    text: widget.existing?.exampleSentence,
  );
  late final _exampleTranslation = TextEditingController(
    text: widget.existing?.exampleTranslation,
  );
  late final _grammar = TextEditingController(
    text: widget.existing?.grammarInfo,
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  bool get _hasDetails => [
    widget.existing?.lemma,
    widget.existing?.partOfSpeech,
    widget.existing?.exampleSentence,
    widget.existing?.exampleTranslation,
    widget.existing?.grammarInfo,
    widget.existing?.notes,
  ].any((v) => v != null);

  @override
  void dispose() {
    for (final c in [
      _word,
      ..._meanings,
      _lemma,
      _partOfSpeech,
      _example,
      _exampleTranslation,
      _grammar,
      _notes,
    ]) {
      c.dispose();
    }
    _wordFocus.dispose();
    super.dispose();
  }

  VocabularyDraft _draft() => VocabularyDraft(
    deckId: _deckId,
    original: _word.text,
    meanings: [for (final c in _meanings) VocabularyMeaning(c.text)],
    lemma: _lemma.text,
    partOfSpeech: _partOfSpeech.text,
    exampleSentence: _example.text,
    exampleTranslation: _exampleTranslation.text,
    grammarInfo: _grammar.text,
    notes: _notes.text,
    sourceContext: widget.existing?.sourceContext,
    sourceType: widget.existing?.sourceType ?? VocabularySourceType.manual,
  ).cleaned();

  void _clearForNext() {
    _word.clear();
    for (final c in _meanings.skip(1)) {
      c.dispose();
    }
    _meanings
      ..removeRange(1, _meanings.length)
      ..first.clear();
    for (final c in [
      _lemma,
      _partOfSpeech,
      _example,
      _exampleTranslation,
      _grammar,
      _notes,
    ]) {
      c.clear();
    }
    _formKey.currentState?.reset();
    _wordFocus.requestFocus();
  }

  Future<void> _save({required bool addAnother}) async {
    if (!_formKey.currentState!.validate()) return;
    final draft = _draft();
    final repository = ref.read(vocabularyRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    setState(() => _saving = true);
    try {
      final matches = await repository.findByNormalized(
        draft.deckId,
        draft.normalized,
      );
      if (!mounted) return;
      // Not busy while waiting for the user's decision.
      setState(() => _saving = false);
      final choice = await showDuplicateDialog(
        context,
        check: checkDuplicate(
          draft,
          matches,
          excludeEntryId: widget.existing?.id,
        ),
        word: draft.original,
        isEditing: _isEditing,
      );
      if (!mounted) return;
      if (choice is AddMeaningsToExisting || choice is SaveAsNew) {
        setState(() => _saving = true);
      }

      final String message;
      switch (choice) {
        case CancelSave():
          return;
        case OpenExisting(:final entry):
          context.go(AppRoutes.entry(entry.deckId, entry.id));
          return;
        case AddMeaningsToExisting(:final entry):
          final merged = await repository.mergeIntoEntry(entry.id, draft);
          message = l10n.entryMergedMessage(bidiIsolate(merged.original));
        case SaveAsNew():
          final saved = _isEditing
              ? await repository.updateEntry(widget.existing!.id, draft)
              : await repository.createEntry(draft);
          message = l10n.entrySavedMessage(bidiIsolate(saved.original));
      }

      messenger.showSnackBar(SnackBar(content: Text(message)));
      if (!mounted) return;
      if (addAnother) {
        _clearForNext();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.deck(draft.deckId));
      }
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateWord(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = (value ?? '').trim();
    if (text.isEmpty) return l10n.errorWordEmpty;
    if (text.runes.length > AppConfig.maxOriginalLength) {
      return l10n.errorTooLong(AppConfig.maxOriginalLength);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final decks = ref.watch(deckSummariesProvider).value ?? const [];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.lg,
          AppSpace.gutter,
          AppSpace.xxl,
        ),
        children: [
          if (!_isEditing && decks.length > 1) ...[
            DropdownButtonFormField<String>(
              key: const Key('entryForm.deck'),
              initialValue: _deckId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.formDeckLabel),
              items: [
                for (final s in decks)
                  DropdownMenuItem(
                    value: s.deck.id,
                    child: AutoDirectionText(s.deck.name),
                  ),
              ],
              onChanged: (id) => setState(() => _deckId = id ?? _deckId),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          TextFormField(
            key: const Key('entryForm.word'),
            controller: _word,
            focusNode: _wordFocus,
            autofocus: !_isEditing,
            textDirection: TextDirection.ltr,
            style: AppTypography.wordTitle,
            // Several lines are allowed, e.g. "Der Nachbar" and
            // "Die Nachbarin" as one entry; Return starts a new line.
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: 4,
            maxLength: AppConfig.maxOriginalLength,
            decoration: InputDecoration(
              labelText: l10n.formWordLabel,
              hintText: l10n.formWordHint,
              hintTextDirection: TextDirection.ltr,
              counterText: '',
            ),
            validator: _validateWord,
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.entryMeanings),
          for (final (index, controller) in _meanings.indexed) ...[
            TextFormField(
              key: Key('entryForm.meaning.$index'),
              controller: controller,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.next,
              maxLength: AppConfig.maxMeaningLength,
              decoration: InputDecoration(
                labelText: l10n.formMeaningLabel(index + 1),
                counterText: '',
                suffixIcon: _meanings.length > 1
                    ? IconButton(
                        tooltip: l10n.formRemoveMeaning,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          _meanings.removeAt(index).dispose();
                        }),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('entryForm.addMeaning'),
              onPressed: _meanings.length >= AppConfig.maxMeaningsPerEntry
                  ? null
                  : () =>
                        setState(() => _meanings.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: Text(l10n.formAddMeaning),
            ),
          ),
          Text(
            l10n.formMeaningsHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          ExpansionTile(
            key: const Key('entryForm.details'),
            title: Text(
              l10n.formMoreDetails,
              style: theme.textTheme.titleSmall,
            ),
            initiallyExpanded: _hasDetails,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: AppSpace.sm),
            children: [
              _field(
                const Key('entryForm.example'),
                _example,
                l10n.formExampleLabel,
                TextDirection.ltr,
                maxLines: 3,
              ),
              _field(
                const Key('entryForm.exampleTranslation'),
                _exampleTranslation,
                l10n.formExampleTranslationLabel,
                TextDirection.rtl,
                maxLines: 3,
              ),
              _field(
                const Key('entryForm.grammar'),
                _grammar,
                l10n.formGrammarLabel,
                TextDirection.ltr,
                hint: l10n.formGrammarHint,
              ),
              _field(
                const Key('entryForm.partOfSpeech'),
                _partOfSpeech,
                l10n.formPartOfSpeechLabel,
                TextDirection.ltr,
                hint: l10n.formPartOfSpeechHint,
              ),
              _field(
                const Key('entryForm.lemma'),
                _lemma,
                l10n.formLemmaLabel,
                TextDirection.ltr,
              ),
              _field(
                const Key('entryForm.notes'),
                _notes,
                l10n.formNotesLabel,
                TextDirection.rtl,
                maxLines: 5,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(
            key: const Key('entryForm.save'),
            onPressed: _saving ? null : () => _save(addAnother: false),
            child: _saving ? const ButtonProgress() : Text(l10n.actionSave),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              key: const Key('entryForm.saveAndNext'),
              onPressed: _saving ? null : () => _save(addAnother: true),
              child: Text(l10n.actionSaveAndAddAnother),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(
    Key key,
    TextEditingController controller,
    String label,
    TextDirection direction, {
    String? hint,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.md),
    child: TextFormField(
      key: key,
      controller: controller,
      textDirection: direction,
      // German input uses the book face; Persian input the UI face.
      style: direction == TextDirection.ltr ? AppTypography.germanBody : null,
      minLines: 1,
      maxLines: maxLines,
      maxLength: AppConfig.maxTextFieldLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: direction,
        counterText: '',
      ),
    ),
  );
}
