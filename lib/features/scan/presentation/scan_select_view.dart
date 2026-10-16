import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/scan_image_source.dart';
import '../domain/scan_document.dart';
import '../domain/text_tokenizer.dart';
import 'scan_controller.dart';

/// Shows the recognized German text and lets the user select words and
/// contiguous expressions.
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
          spacing: 8,
          runSpacing: 8,
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

    final notice = switch (state.notice) {
      SelectionNotice.pickExpressionEnd => l10n.scanExpressionPickEnd,
      SelectionNotice.expressionTooLong => l10n.scanExpressionTooLong(
        AppConfig.maxExpressionWords,
      ),
      SelectionNotice.selectionsDropped => l10n.scanSelectionsDropped(
        state.droppedCount,
      ),
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.scanSelectHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Text(
                  notice,
                  key: const Key('scan.notice'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Directionality(
            // German text always reads left to right.
            textDirection: TextDirection.ltr,
            child: ListView(
              key: const Key('scan.text'),
              padding: const EdgeInsets.all(16),
              children: [
                for (final paragraph in document.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Wrap(
                      runSpacing: 4,
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
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.scanSelectedCount(state.selection.length),
                  key: const Key('scan.selectedCount'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('scan.review'),
                  onPressed: state.selection.isEmpty
                      ? null
                      : controller.goToReview,
                  child: Text(l10n.scanReviewButton(state.selection.length)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium;

    if (!token.isWord) {
      // Punctuation and spacing; line breaks inside a paragraph reflow.
      final text = token.source.replaceAll(RegExp(r'\s+'), ' ');
      if (text.trim().isEmpty) return const SizedBox(width: 4);
      return Text(text.trim(), style: style);
    }

    final selected = state.selection.rangeAt(token.start) != null;
    final isAnchor = state.anchor?.start == token.start;
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        key: Key('scan.word.${token.start}'),
        color: selected
            ? scheme.primaryContainer
            : isAnchor
            ? scheme.tertiaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onTap(token),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                token.display,
                textAlign: TextAlign.center,
                style: style?.copyWith(
                  color: selected ? scheme.onPrimaryContainer : null,
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
