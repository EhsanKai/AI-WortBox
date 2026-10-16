import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/scan_image_source.dart';
import 'scan_controller.dart';
import 'scan_review_view.dart';
import 'scan_select_view.dart';

/// Photo/gallery/typed text → select words → review → save.
///
/// All steps live in one route so the session state is kept together; the
/// back button moves to the previous step.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.initialDeckId});

  final String? initialDeckId;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(scanControllerProvider(widget.initialDeckId).notifier)
          .recoverLostImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = scanControllerProvider(widget.initialDeckId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    final canPop =
        state.step == ScanStep.capture || state.step == ScanStep.done;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (state.step) {
          case ScanStep.typing:
          case ScanStep.select:
            controller.backToCapture();
          case ScanStep.review:
            controller.backToSelect();
          case ScanStep.capture:
          case ScanStep.done:
            break;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (state.step) {
            ScanStep.review => l10n.scanReviewTitle,
            _ => l10n.scanTitle,
          }),
          actions: [
            if (state.step == ScanStep.select &&
                (state.document?.hasWords ?? false)) ...[
              IconButton(
                key: const Key('scan.editText'),
                tooltip: l10n.scanEditText,
                icon: const Icon(Icons.edit_note),
                onPressed: () => _editText(context, state),
              ),
              IconButton(
                key: const Key('scan.clearSelection'),
                tooltip: l10n.scanClearSelection,
                icon: const Icon(Icons.deselect),
                onPressed: state.selection.isEmpty
                    ? null
                    : controller.clearSelection,
              ),
            ],
          ],
        ),
        body: switch (state.step) {
          ScanStep.capture => _CaptureView(
            state: state,
            controller: controller,
          ),
          ScanStep.typing => _TypingView(controller: controller),
          ScanStep.select => ScanSelectView(
            initialDeckId: widget.initialDeckId,
          ),
          ScanStep.review => ScanReviewView(
            initialDeckId: widget.initialDeckId,
          ),
          ScanStep.done => _DoneView(state: state, controller: controller),
        },
      ),
    );
  }

  Future<void> _editText(BuildContext context, ScanState state) async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController(text: state.document!.text);
    final edited = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scanEditTextTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            key: const Key('scan.editTextField'),
            controller: textController,
            textDirection: TextDirection.ltr,
            maxLines: 12,
            minLines: 4,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('scan.editTextSave'),
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    textController.dispose();
    if (edited != null) {
      ref
          .read(scanControllerProvider(widget.initialDeckId).notifier)
          .editText(edited);
    }
  }
}

class _CaptureView extends StatelessWidget {
  const _CaptureView({required this.state, required this.controller});

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (state.isBusy) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.scanRecognizing),
          ],
        ),
      );
    }

    final error = state.error;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.scanIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text(
          l10n.scanOcrWarning,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Card.filled(
            key: const Key('scan.error'),
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                error is ScanException && error.isPermissionError
                    ? Icons.no_photography_outlined
                    : Icons.error_outline,
                color: theme.colorScheme.onErrorContainer,
              ),
              title: Text(
                errorMessage(l10n, error),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('scan.camera'),
          onPressed: () => controller.pickImage(ImageOrigin.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.scanTakePhoto),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('scan.gallery'),
          onPressed: () => controller.pickImage(ImageOrigin.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l10n.scanChoosePhoto),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('scan.typeText'),
          onPressed: controller.startTyping,
          icon: const Icon(Icons.keyboard_outlined),
          label: Text(l10n.scanTypeText),
        ),
      ],
    );
  }
}

class _TypingView extends StatefulWidget {
  const _TypingView({required this.controller});

  final ScanController controller;

  @override
  State<_TypingView> createState() => _TypingViewState();
}

class _TypingViewState extends State<_TypingView> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const Key('scan.typedText'),
          controller: _text,
          autofocus: true,
          textDirection: TextDirection.ltr,
          minLines: 6,
          maxLines: 16,
          decoration: InputDecoration(
            hintText: l10n.scanTypedHint,
            hintTextDirection: TextDirection.ltr,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('scan.useText'),
          onPressed: _text.text.trim().isEmpty
              ? null
              : () => widget.controller.useTypedText(_text.text),
          child: Text(l10n.scanUseText),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.state, required this.controller});

  final ScanState state;
  final ScanController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = state.result!;
    return ListView(
      key: const Key('scan.done'),
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.scanSavedTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(l10n.scanResultCreated(summary.createdCount)),
        ),
        if (summary.mergedCount > 0)
          ListTile(
            leading: const Icon(Icons.merge_type),
            title: Text(l10n.scanResultMerged(summary.mergedCount)),
          ),
        if (summary.skippedCount > 0)
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: Text(l10n.scanResultSkipped(summary.skippedCount)),
          ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('scan.viewDeck'),
          onPressed: () => context.go(AppRoutes.deck(state.deckId!)),
          child: Text(l10n.csvViewDeck),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('scan.another'),
          onPressed: controller.reset,
          child: Text(l10n.scanScanAnother),
        ),
      ],
    );
  }
}
