import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/scan_image_source.dart';
import '../domain/scan_document.dart';
import '../domain/text_tokenizer.dart';
import 'scan_controller.dart';
import 'scan_image_select_view.dart';

/// Shows the page — the photo with selectable words when OCR placed them,
/// otherwise the recognized German text — and lets the user select words
/// and contiguous expressions.
class ScanSelectView extends ConsumerWidget {
  const ScanSelectView({super.key, required this.initialDeckId});

  final String? initialDeckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = scanControllerProvider(initialDeckId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final document = state.document!;

    if (!document.hasWords) {
      return EmptyStateView(
        icon: Icons.text_snippet_outlined,
        title: l10n.scanNoTextTitle,
        message: l10n.scanNoTextBody,
        action: Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonal(
              key: const Key('scan.tryAgain'),
              onPressed: () => controller.pickImage(ImageOrigin.gallery),
              child: Text(l10n.scanTryAgain),
            ),
            OutlinedButton(
              key: const Key('scan.typeInstead'),
              onPressed: controller.startTyping,
              child: Text(l10n.scanTypeText),
            ),
          ],
        ),
      );
    }

    if (state.view == ScanView.image && state.canShowImage) {
      return ScanImageSelectView(initialDeckId: initialDeckId);
    }

    final (notice, noticeTone) = switch (state.notice) {
      SelectionNotice.pickExpressionEnd => (
        l10n.scanExpressionPickEnd,
        StatusTone.accent,
      ),
      SelectionNotice.expressionTooLong => (
        l10n.scanExpressionTooLong(AppConfig.maxExpressionWords),
        StatusTone.warning,
      ),
      SelectionNotice.selectionsDropped => (
        l10n.scanSelectionsDropped(state.droppedCount),
        StatusTone.warning,
      ),
      SelectionNotice.regionEmpty => (l10n.scanRegionEmpty, StatusTone.warning),
      SelectionNotice.regionFailed => (
        l10n.scanRegionFailed,
        StatusTone.warning,
      ),
      null => (null, StatusTone.neutral),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions and the page scroll together, so the page keeps its
        // room on small screens and with large text.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xs,
              AppSpace.gutter,
              AppSpace.md,
            ),
            children: [
              Text(
                l10n.scanSelectHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SegmentedButton<SelectionMode>(
                key: const Key('scan.mode'),
                segments: [
                  ButtonSegment(
                    value: SelectionMode.word,
                    label: Text(l10n.scanModeWord),
                    icon: const Icon(Icons.touch_app_outlined),
                  ),
                  ButtonSegment(
                    value: SelectionMode.expression,
                    label: Text(l10n.scanModeExpression),
                    icon: const Icon(Icons.linear_scale),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (s) => controller.setMode(s.first),
              ),
              if (notice != null) ...[
                const SizedBox(height: AppSpace.sm),
                InfoBanner(
                  key: const Key('scan.notice'),
                  tone: noticeTone,
                  message: notice,
                ),
              ],
              const SizedBox(height: AppSpace.md),
              // The recognized text on a paper-like reading surface.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.paper,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Directionality(
                    // German text always reads left to right.
                    textDirection: TextDirection.ltr,
                    child: Column(
                      key: const Key('scan.text'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final paragraph in document.paragraphs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.md),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final index in paragraph)
                                  _TokenView(
                                    token: document.tokens[index],
                                    document: document,
                                    state: state,
                                    onTap: controller.tapWord,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.md,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    // Repeats the button's count, so one line is enough even
                    // with large text.
                    child: Text(
                      l10n.scanSelectedCount(state.selectedCount),
                      key: const Key('scan.selectedCount'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  FilledButton(
                    key: const Key('scan.review'),
                    onPressed: state.selectedCount == 0
                        ? null
                        : controller.goToReview,
                    child: Text(l10n.scanReviewButton(state.selectedCount)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One token of the recognized text. Words are tap targets of at least
/// 48×48 logical pixels; the visible highlight hugs the word like a
/// highlighter stroke.
class _TokenView extends StatelessWidget {
  const _TokenView({
    required this.token,
    required this.document,
    required this.state,
    required this.onTap,
  });

  final TextToken token;
  final ScanDocument document;
  final ScanState state;
  final ValueChanged<TextToken> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final style = AppTypography.pageText.copyWith(
      color: theme.colorScheme.onSurface,
    );

    if (!token.isWord) {
      // Punctuation and spacing; line breaks inside a paragraph reflow.
      final text = token.source.replaceAll(RegExp(r'\s+'), ' ');
      if (text.trim().isEmpty) return const SizedBox.shrink();
      return ExcludeSemantics(child: Text(text.trim(), style: style));
    }

    final selected = state.selection.rangeAt(token.start) != null;
    final isAnchor = state.anchor?.start == token.start;
    final scheme = theme.colorScheme;
    return Semantics(
      key: Key('scan.word.${token.start}'),
      button: true,
      selected: selected,
      label: token.display,
      onTapHint: selected
          ? l10n.scanWordTapToDeselect
          : l10n.scanWordTapToSelect,
      onTap: () => onTap(token),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: () => onTap(token),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppTouch.minTarget,
            minWidth: AppTouch.minTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: AppMotion.quick,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xs + AppSpace.xxs,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? colors.highlight
                    : isAnchor
                    ? scheme.tertiaryContainer
                    : null,
                borderRadius: AppRadius.smAll,
                border: isAnchor
                    ? Border.all(
                        color: scheme.tertiary,
                        width: AppBorder.emphasis,
                      )
                    : null,
              ),
              child: Text(
                token.display,
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: selected ? colors.onHighlight : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                  decoration: token.isJoinedAcrossLines
                      ? TextDecoration.underline
                      : null,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
