import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/deck.dart';

/// Shows the create-deck form. Returns the created deck, or null if the user
/// cancelled.
Future<Deck?> showCreateDeckSheet(BuildContext context) {
  return showModalBottomSheet<Deck>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const CreateDeckSheet(),
  );
}

class CreateDeckSheet extends ConsumerStatefulWidget {
  const CreateDeckSheet({super.key});

  @override
  ConsumerState<CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends ConsumerState<CreateDeckSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController(
    text: '${AppConfig.defaultDailyNewCardLimit}',
  );

  bool _submitting = false;

  /// Errors reported by the repository (e.g. duplicate name), shown inline.
  Set<DeckValidationError> _serverErrors = const {};

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  DeckDraft _draft() => DeckDraft(
    name: _nameController.text,
    dailyNewCardLimit:
        int.tryParse(_limitController.text.trim()) ??
        AppConfig.defaultDailyNewCardLimit,
  );

  Future<void> _submit() async {
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final deck = await ref.read(deckRepositoryProvider).createDeck(_draft());
      if (mounted) Navigator.of(context).pop(deck);
    } on DeckValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(AppLocalizations.of(context), e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateName(String? _) {
    final l10n = AppLocalizations.of(context);
    final errors = {..._draft().validate(), ..._serverErrors};
    if (errors.contains(DeckValidationError.nameEmpty)) {
      return l10n.errorDeckNameEmpty;
    }
    if (errors.contains(DeckValidationError.nameTooLong)) {
      return l10n.errorDeckNameTooLong(AppConfig.maxDeckNameLength);
    }
    if (errors.contains(DeckValidationError.nameDuplicate)) {
      return l10n.errorDeckNameDuplicate;
    }
    return null;
  }

  String? _validateLimit(String? value) {
    final l10n = AppLocalizations.of(context);
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return l10n.errorInvalidNumber;
    if (parsed < AppConfig.minDailyNewCardLimit ||
        parsed > AppConfig.maxDailyNewCardLimit) {
      return l10n.errorDailyLimitRange(
        AppConfig.minDailyNewCardLimit,
        AppConfig.maxDailyNewCardLimit,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const source = AppConfig.defaultSourceLanguage;
    const definition = AppConfig.defaultDefinitionLanguage;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.createDeckTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('createDeck.name'),
              controller: _nameController,
              autofocus: true,
              maxLength: AppConfig.maxDeckNameLength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.createDeckNameLabel,
                hintText: l10n.createDeckNameHint,
              ),
              validator: _validateName,
              onChanged: (_) {
                if (_serverErrors.isNotEmpty) {
                  setState(() => _serverErrors = const {});
                }
              },
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.createDeckLanguagesLabel,
                enabled: false,
              ),
              child: Text(
                l10n.deckLanguagePair(source.nativeName, definition.nativeName),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('createDeck.dailyLimit'),
              controller: _limitController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.createDeckDailyLimitLabel,
                helperText: l10n.createDeckDailyLimitHelper(
                  AppConfig.minDailyNewCardLimit,
                  AppConfig.maxDailyNewCardLimit,
                ),
                helperMaxLines: 2,
              ),
              validator: _validateLimit,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.actionCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('createDeck.submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.createDeckSubmit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
