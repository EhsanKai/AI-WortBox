import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/ai_model_catalog.dart';
import 'ai_settings_controller.dart';

/// Bring-your-own-key setup: explanation, key entry/replacement/removal,
/// key test, model choice, privacy and security notes.
class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(aiSettingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiSettingsTitle)),
      body: switch (settings) {
        AsyncData(:final value) => _AiSettingsBody(state: value),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(aiSettingsControllerProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _AiSettingsBody extends ConsumerStatefulWidget {
  const _AiSettingsBody({required this.state});

  final AiSettingsState state;

  @override
  ConsumerState<_AiSettingsBody> createState() => _AiSettingsBodyState();
}

class _AiSettingsBodyState extends ConsumerState<_AiSettingsBody> {
  final _key = TextEditingController();
  bool _obscured = true;
  bool _replacing = false;
  bool _saving = false;
  ApiKeyProblem? _problem;

  /// Message for a failed secure-storage write of the key, if any.
  String? _storageError;

  /// Set when saving the model choice failed.
  bool _modelSaveFailed = false;

  /// Bumped to reset the model dropdown after a failed change.
  int _modelResets = 0;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  AiSettingsController get _controller =>
      ref.read(aiSettingsControllerProvider.notifier);

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _problem = null;
      _storageError = null;
    });
    try {
      await _controller.saveKey(_key.text);
      // The typed key is not kept in the widget once it is stored.
      _key.clear();
      if (mounted) setState(() => _replacing = false);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _problem = e.invalidValue as ApiKeyProblem);
    } on StorageException {
      if (mounted) setState(() => _storageError = l10n.aiKeySaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.aiKeyRemoveTitle),
        content: Text(l10n.aiKeyRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('ai.confirmRemove'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.aiKeyRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _storageError = null);
    try {
      await _controller.removeKey();
    } on StorageException {
      if (mounted) setState(() => _storageError = l10n.aiKeyRemoveFailed);
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.aiKeyRemoved)));
  }

  Future<void> _selectModel(String id) async {
    setState(() => _modelSaveFailed = false);
    try {
      await _controller.selectModel(id);
    } on StorageException {
      if (!mounted) return;
      setState(() {
        _modelSaveFailed = true;
        _modelResets++;
      });
    }
  }

  String? _problemText(AppLocalizations l10n) => switch (_problem) {
    ApiKeyProblem.empty => l10n.aiKeyProblemEmpty,
    ApiKeyProblem.containsWhitespace => l10n.aiKeyProblemWhitespace,
    ApiKeyProblem.tooShort => l10n.aiKeyProblemShort,
    ApiKeyProblem.tooLong => l10n.aiKeyProblemLong,
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = widget.state;
    final showField = !state.isConfigured || _replacing;
    const gap = SizedBox(height: AppSpace.xl);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusBadge(
            key: const Key('ai.status'),
            icon: state.isConfigured ? Icons.check : Icons.power_settings_new,
            tone: state.isConfigured ? StatusTone.success : StatusTone.neutral,
            label: state.isConfigured
                ? l10n.settingsAiConfigured
                : l10n.settingsAiNotConfigured,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.aiIntroTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpace.xs),
                Text(l10n.aiIntroBody, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpace.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('ai.getKey'),
                    onPressed: () => ref.read(urlLauncherProvider)(
                      Uri.parse(AppConfig.openRouterKeysUrl),
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.aiGetKey),
                  ),
                ),
              ],
            ),
          ),
        ),
        gap,
        SectionHeader(l10n.aiKeyLabel),
        if (_storageError case final message?) ...[
          InfoBanner(
            key: const Key('ai.storageError'),
            tone: StatusTone.danger,
            message: message,
          ),
          const SizedBox(height: AppSpace.md),
        ],
        if (state.keySuffix case final suffix? when !_replacing) ...[
          Text(
            l10n.aiKeySaved(suffix),
            key: const Key('ai.savedKey'),
            textDirection: TextDirection.ltr,
            textAlign: Directionality.of(context) == TextDirection.rtl
                ? TextAlign.right
                : TextAlign.left,
            style: theme.textTheme.titleMedium,
          ),
          Text(l10n.aiKeySavedNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpace.md),
          FilledButton.tonalIcon(
            key: const Key('ai.test'),
            onPressed: state.check is AiKeyCheckRunning
                ? null
                : _controller.testKey,
            icon: const Icon(Icons.verified_outlined),
            label: Text(l10n.aiKeyTest),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton.icon(
            key: const Key('ai.replace'),
            onPressed: () => setState(() => _replacing = true),
            icon: const Icon(Icons.swap_horiz),
            label: Text(l10n.aiKeyReplace),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton.icon(
            key: const Key('ai.remove'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: _remove,
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.aiKeyRemove),
          ),
        ],
        if (showField) ...[
          TextField(
            key: const Key('ai.keyField'),
            controller: _key,
            obscureText: _obscured,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            keyboardType: TextInputType.visiblePassword,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: state.isConfigured
                  ? l10n.aiKeyNewLabel
                  : l10n.aiKeyLabel,
              hintText: 'sk-or-v1-…',
              hintTextDirection: TextDirection.ltr,
              errorText: _problemText(l10n),
              suffixIcon: IconButton(
                key: const Key('ai.toggleVisibility'),
                tooltip: _obscured ? l10n.aiKeyShow : l10n.aiKeyHide,
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(
            key: const Key('ai.save'),
            onPressed: _saving ? null : _save,
            child: _saving ? const ButtonProgress() : Text(l10n.aiKeySave),
          ),
          if (_replacing) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              onPressed: () => setState(() {
                _replacing = false;
                _problem = null;
                _key.clear();
              }),
              child: Text(l10n.actionCancel),
            ),
          ],
        ],
        _CheckResult(check: state.check),
        gap,
        SectionHeader(l10n.aiModelLabel),
        // A failed change resets the field to the stored model.
        KeyedSubtree(
          key: ValueKey(_modelResets),
          child: DropdownButtonFormField<String>(
            key: const Key('ai.model'),
            initialValue: state.model,
            isExpanded: true,
            decoration: InputDecoration(helperText: l10n.aiModelHelper),
            items: [
              for (final m in AiModelCatalog.models)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(m.label, textDirection: TextDirection.ltr),
                ),
            ],
            onChanged: (id) {
              if (id != null) _selectModel(id);
            },
          ),
        ),
        if (_modelSaveFailed) ...[
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            key: const Key('ai.modelError'),
            tone: StatusTone.danger,
            message: l10n.aiModelSaveFailed,
          ),
        ],
        gap,
        SectionHeader(l10n.aiPrivacyTitle),
        InfoBanner(icon: Icons.public, message: l10n.aiPrivacyBody),
        gap,
        SectionHeader(l10n.aiSecurityTitle),
        InfoBanner(icon: Icons.lock_outline, message: l10n.aiSecurityBody),
      ],
    );
  }
}

class _CheckResult extends StatelessWidget {
  const _CheckResult({required this.check});

  final AiKeyCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = intl.NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 4,
    );
    final Widget? content = switch (check) {
      AiKeyCheckIdle() => null,
      AiKeyCheckRunning() => Row(
        children: [
          const ButtonProgress(),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(l10n.aiCheckRunning)),
        ],
      ),
      AiKeyCheckPassed(:final info, :final modelAvailable) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            tone: StatusTone.success,
            message: [
              l10n.aiCheckPassed,
              // Only figures OpenRouter reported; nothing is estimated.
              if (info.usage case final usage?)
                l10n.aiCheckUsage(money.format(usage)),
              if (info.limitRemaining case final remaining?)
                l10n.aiCheckRemaining(money.format(remaining)),
            ].join('\n'),
          ),
          if (modelAvailable != true) ...[
            const SizedBox(height: AppSpace.sm),
            InfoBanner(
              key: const Key('ai.modelWarning'),
              tone: StatusTone.warning,
              message: modelAvailable == false
                  ? l10n.aiCheckModelUnavailable
                  : l10n.aiCheckModelUnknown,
            ),
          ],
        ],
      ),
      AiKeyCheckFailed(:final error) => InfoBanner(
        tone: StatusTone.danger,
        message: errorMessage(l10n, error),
      ),
    };
    if (content == null) return const SizedBox.shrink();
    return Padding(
      key: const Key('ai.checkResult'),
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: content,
    );
  }
}
