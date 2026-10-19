import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
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
            if (state.step == ScanStep.select && state.canShowImage)
              IconButton(
                key: const Key('scan.toggleView'),
                tooltip: state.view == ScanView.image
                    ? l10n.scanViewText
                    : l10n.scanViewImage,
                icon: Icon(
                  state.view == ScanView.image
                      ? Icons.notes
                      : Icons.image_outlined,
                ),
                onPressed: () => controller.setView(
                  state.view == ScanView.image ? ScanView.text : ScanView.image,
                ),
              ),
            if (state.step == ScanStep.select &&
                (state.document?.hasWords ?? false)) ...[
              if (state.view == ScanView.text || !state.canShowImage)
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
                onPressed: state.selectedCount == 0
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
        scrollable: true,
        title: Text(l10n.scanEditTextTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            key: const Key('scan.editTextField'),
            controller: textController,
            textDirection: TextDirection.ltr,
            style: AppTypography.germanBody,
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

    if (state.isBusy) return LoadingView(message: l10n.scanRecognizing);

    final error = state.error;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandMark(size: 56),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Text(l10n.scanIntro, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpace.lg),
          InfoBanner(
            key: const Key('scan.error'),
            tone: StatusTone.danger,
            icon: error is ScanException && error.isPermissionError
                ? Icons.no_photography_outlined
                : Icons.error_outline,
            message: errorMessage(l10n, error),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        FilledButton.icon(
          key: const Key('scan.camera'),
          onPressed: () => controller.pickImage(ImageOrigin.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.scanTakePhoto),
        ),
        const SizedBox(height: AppSpace.sm),
        FilledButton.tonalIcon(
          key: const Key('scan.gallery'),
          onPressed: () => controller.pickImage(ImageOrigin.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(l10n.scanChoosePhoto),
        ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton.icon(
          key: const Key('scan.typeText'),
          onPressed: controller.startTyping,
          icon: const Icon(Icons.keyboard_outlined),
          label: Text(l10n.scanTypeText),
        ),
        const SizedBox(height: AppSpace.xl),
        InfoBanner(tone: StatusTone.warning, message: l10n.scanOcrWarning),
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
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        TextField(
          key: const Key('scan.typedText'),
          controller: _text,
          autofocus: true,
          textDirection: TextDirection.ltr,
          style: AppTypography.germanBody,
          minLines: 6,
          maxLines: 16,
          decoration: InputDecoration(
            hintText: l10n.scanTypedHint,
            hintTextDirection: TextDirection.ltr,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.lg),
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
    final summary = state.result!;
    return OutcomeView(
      key: const Key('scan.done'),
      title: l10n.scanSavedTitle,
      lines: [
        OutcomeLine(
          Icons.add_circle_outline,
          l10n.scanResultCreated(summary.createdCount),
          tone: StatusTone.success,
        ),
        if (summary.mergedCount > 0)
          OutcomeLine(
            Icons.merge_type,
            l10n.scanResultMerged(summary.mergedCount),
          ),
        if (summary.skippedCount > 0)
          OutcomeLine(
            Icons.copy_all_outlined,
            l10n.scanResultSkipped(summary.skippedCount),
          ),
      ],
      primary: FilledButton(
        key: const Key('scan.viewDeck'),
        onPressed: () => context.go(AppRoutes.deck(state.deckId!)),
        child: Text(l10n.csvViewDeck),
      ),
      secondary: OutlinedButton(
        key: const Key('scan.another'),
        onPressed: controller.reset,
        child: Text(l10n.scanScanAnother),
      ),
    );
  }
}
