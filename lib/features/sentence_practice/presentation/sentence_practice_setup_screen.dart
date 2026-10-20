import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/text/bidi.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../enrichment/presentation/ai_settings_controller.dart';
import '../../tags/presentation/tag_providers.dart';
import '../domain/sentence_practice.dart';
import 'sentence_practice_controller.dart';
import 'sentence_practice_providers.dart';

String sentenceLevelLabel(AppLocalizations l10n, SentenceLevel level) =>
    switch (level) {
      SentenceLevel.a2 => l10n.spLevelA2,
      SentenceLevel.b1 => l10n.spLevelB1,
      SentenceLevel.b2 => l10n.spLevelB2,
    };

/// Chooses how to practise sentences: direction, level, number of words
/// and (optionally) a deck or tag.
class SentencePracticeSetupScreen extends ConsumerStatefulWidget {
  const SentencePracticeSetupScreen({super.key});

  @override
  ConsumerState<SentencePracticeSetupScreen> createState() =>
      _SentencePracticeSetupScreenState();
}

class _SentencePracticeSetupScreenState
    extends ConsumerState<SentencePracticeSetupScreen> {
  var _config = const SentenceSessionConfig();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final decks = ref.watch(deckSummariesProvider).value ?? const [];
    final tags = ref.watch(tagsProvider).value ?? const [];
    final configured = ref.watch(aiConfiguredProvider);
    final history = ref.watch(sentencePracticeCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.spTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxl,
        ),
        children: [
          Text(l10n.spIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            key: const Key('sp.separateNote'),
            icon: Icons.event_repeat,
            message: l10n.spSeparateNote,
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.spDirectionTitle),
          RadioGroup<SentencePracticeDirection>(
            groupValue: _config.direction,
            onChanged: (value) {
              if (value != null) {
                setState(() => _config = _copy(direction: value));
              }
            },
            child: Column(
              children: [
                for (final direction in SentencePracticeDirection.values)
                  RadioListTile<SentencePracticeDirection>(
                    key: Key('sp.direction.${direction.name}'),
                    contentPadding: EdgeInsets.zero,
                    value: direction,
                    title: Text(switch (direction) {
                      SentencePracticeDirection.produce =>
                        l10n.spDirectionProduce,
                      SentencePracticeDirection.understand =>
                        l10n.spDirectionUnderstand,
                    }),
                    subtitle: Text(switch (direction) {
                      SentencePracticeDirection.produce =>
                        l10n.spDirectionProduceHint,
                      SentencePracticeDirection.understand =>
                        l10n.spDirectionUnderstandHint,
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          SectionHeader(l10n.spLevelTitle),
          SegmentedButton<SentenceLevel>(
            key: const Key('sp.level'),
            showSelectedIcon: false,
            segments: [
              for (final level in SentenceLevel.values)
                ButtonSegment(
                  value: level,
                  label: Text(sentenceLevelLabel(l10n, level)),
                ),
            ],
            selected: {_config.level},
            onSelectionChanged: (s) =>
                setState(() => _config = _copy(level: s.single)),
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.spSizeTitle),
          SegmentedButton<int>(
            key: const Key('sp.size'),
            showSelectedIcon: false,
            segments: [
              for (final size in AppConfig.sentencePracticeSizes)
                ButtonSegment(value: size, label: Text(l10n.spSizeWords(size))),
            ],
            selected: {_config.size},
            onSelectionChanged: (s) =>
                setState(() => _config = _copy(size: s.single)),
          ),
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.practiceWordsFrom),
          DropdownButtonFormField<String?>(
            key: const Key('sp.deck'),
            initialValue: _config.deckId,
            isExpanded: true,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.practiceAllDecks),
              ),
              for (final s in decks)
                DropdownMenuItem<String?>(
                  value: s.deck.id,
                  child: Text(
                    bidiIsolate(s.deck.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) =>
                setState(() => _config = _copy(deckId: () => value)),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            DropdownButtonFormField<String?>(
              key: const Key('sp.tag'),
              initialValue: _config.tagId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.spTagLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.spAllTags),
                ),
                for (final t in tags)
                  DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(
                      bidiIsolate(t.name),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _config = _copy(tagId: () => value)),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          InfoBanner(
            key: const Key('sp.aiNote'),
            icon: Icons.auto_awesome_outlined,
            message: l10n.spAiNote,
          ),
          const SizedBox(height: AppSpace.lg),
          if (!configured) ...[
            InfoBanner(
              key: const Key('sp.needsKey'),
              tone: StatusTone.warning,
              message: l10n.spNeedsKey,
              action: TextButton(
                onPressed: () => context.go(AppRoutes.aiSettings),
                child: Text(l10n.spOpenAiSettings),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          FilledButton.icon(
            key: const Key('sp.start'),
            onPressed: configured
                ? () => context.push(AppRoutes.sentenceSession(_config))
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.spStart),
          ),
          const SizedBox(height: AppSpace.xl),
          if (history > 0)
            Card(
              child: ListTile(
                key: const Key('sp.clearHistory'),
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(l10n.spClearHistory),
                subtitle: Text(l10n.spHistoryCount(history)),
                onTap: () => _clearHistory(context),
              ),
            ),
        ],
      ),
    );
  }

  SentenceSessionConfig _copy({
    SentencePracticeDirection? direction,
    SentenceLevel? level,
    int? size,
    String? Function()? deckId,
    String? Function()? tagId,
  }) => SentenceSessionConfig(
    direction: direction ?? _config.direction,
    level: level ?? _config.level,
    size: size ?? _config.size,
    deckId: deckId != null ? deckId() : _config.deckId,
    tagId: tagId != null ? tagId() : _config.tagId,
  );

  Future<void> _clearHistory(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.spClearConfirmTitle),
        content: Text(l10n.spClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('sp.clearConfirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.spClearConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(sentencePracticeRepositoryProvider).clearHistory();
      messenger.showSnackBar(SnackBar(content: Text(l10n.spCleared)));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l10n, e))));
    }
  }
}
