import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/auto_direction_text.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../decks/domain/deck.dart';
import '../../decks/presentation/deck_providers.dart';
import '../../decks/presentation/decks_screen.dart';
import '../../vocabulary/domain/duplicate_detection.dart';
import '../../vocabulary/domain/vocabulary_repository.dart';
import '../domain/column_mapping.dart';
import '../domain/csv_import_analysis.dart';
import '../domain/csv_table.dart';
import 'csv_import_controller.dart';

/// Preview rows shown per list before collapsing into "and N more".
const _previewLimit = 50;

class CsvImportScreen extends ConsumerWidget {
  const CsvImportScreen({super.key, this.initialDeckId});

  final String? initialDeckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = csvImportControllerProvider(initialDeckId);
    final state = ref.watch(provider);
    final decks = ref.watch(deckSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addImportCsv)),
      body: switch (decks) {
        AsyncData(:final value) when value.isEmpty => EmptyStateView(
          icon: Icons.inventory_2_outlined,
          title: l10n.formNoDecks,
          action: FilledButton.icon(
            onPressed: () => createDeckAndAnnounce(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.actionCreateDeck),
          ),
        ),
        AsyncData() when state.result != null => _ResultView(
          summary: state.result!,
          errorCount: state.resultErrorCount,
          deckId: state.deckId!,
          onImportAnother: ref.read(provider.notifier).reset,
        ),
        AsyncData(:final value) => _ImportForm(
          initialDeckId: initialDeckId,
          decks: [for (final s in value) s.deck],
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(deckSummariesProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _ImportForm extends ConsumerWidget {
  const _ImportForm({required this.initialDeckId, required this.decks});

  final String? initialDeckId;
  final List<Deck> decks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = csvImportControllerProvider(initialDeckId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final analysis = ref.watch(csvImportAnalysisProvider(initialDeckId));

    final deck = decks.where((d) => d.id == state.deckId).firstOrNull;
    if (deck == null) {
      // No valid preselection: choose the first deck after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (decks.isNotEmpty) controller.selectDeck(decks.first.id);
      });
      return const LoadingView();
    }

    final table = state.table;
    final mapping = state.mapping;
    final preview = analysis.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Text(
          l10n.csvIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _Section(
          title: l10n.csvSectionDeck,
          child: DropdownButtonFormField<String>(
            key: const Key('csv.deck'),
            initialValue: deck.id,
            isExpanded: true,
            items: [
              for (final d in decks)
                DropdownMenuItem(
                  value: d.id,
                  child: AutoDirectionText(d.name, maxLines: 1),
                ),
            ],
            onChanged: state.isImporting
                ? null
                : (id) => controller.selectDeck(id ?? deck.id),
          ),
        ),
        _Section(
          title: l10n.csvSectionFile,
          child: _FileSection(state: state, controller: controller),
        ),
        if (table != null && mapping != null) ...[
          _Section(
            title: l10n.csvSectionColumns,
            child: _ColumnsSection(
              table: table,
              mapping: mapping,
              controller: controller,
            ),
          ),
          _Section(
            title: l10n.csvSectionLanguages,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (preview?.languagesLookSwapped ?? false) ...[
                  InfoBanner(
                    tone: StatusTone.warning,
                    icon: Icons.swap_horiz,
                    message: l10n.csvLanguagesSwapped,
                    action: TextButton(
                      key: const Key('csv.swap'),
                      onPressed: controller.swapLanguageColumns,
                      child: Text(l10n.csvSwapColumns),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                CheckboxListTile(
                  key: const Key('csv.confirmLanguages'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: state.languagesConfirmed,
                  onChanged: (v) =>
                      controller.setLanguagesConfirmed(v ?? false),
                  title: Text(
                    l10n.csvLanguagesConfirm(
                      deck.sourceLanguage.nativeName,
                      deck.definitionLanguage.nativeName,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: l10n.csvSectionDuplicates,
            child: _StrategySection(
              strategy: state.strategy,
              onChanged: controller.setStrategy,
            ),
          ),
          _Section(
            title: l10n.csvSectionPreview,
            child: switch (analysis) {
              AsyncData(value: final a?) => _PreviewSection(analysis: a),
              AsyncData() => Text(l10n.csvMappingNeedsWord),
              AsyncError(:final error) => Text(errorMessage(l10n, error)),
              _ => const LinearProgressIndicator(),
            },
          ),
          if (state.importError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.lg),
              child: InfoBanner(
                tone: StatusTone.danger,
                message: l10n.csvImportFailed,
              ),
            ),
          const SizedBox(height: AppSpace.xl),
          _ImportButton(
            analysis: preview,
            enabled:
                preview != null &&
                preview.actionableCount > 0 &&
                state.languagesConfirmed &&
                !state.isImporting,
            importing: state.isImporting,
            onPressed: () => controller.runImport(preview!),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SectionHeader(title), child],
      ),
    );
  }
}

class _FileSection extends StatelessWidget {
  const _FileSection({required this.state, required this.controller});

  final CsvImportState state;
  final CsvImportController controller;

  static String encodingName(CsvTextEncoding encoding) => switch (encoding) {
    CsvTextEncoding.utf8 => 'UTF-8',
    CsvTextEncoding.utf8Bom => 'UTF-8 (BOM)',
    CsvTextEncoding.utf16le => 'UTF-16 LE',
    CsvTextEncoding.utf16be => 'UTF-16 BE',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final table = state.table;
    final file = state.file;

    String delimiterName(String? d) => switch (d) {
      ',' => l10n.csvDelimiterComma,
      ';' => l10n.csvDelimiterSemicolon,
      '\t' => l10n.csvDelimiterTab,
      '|' => l10n.csvDelimiterPipe,
      _ => l10n.csvDelimiterAuto,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('csv.pickFile'),
          onPressed: state.isLoadingFile || state.isImporting
              ? null
              : controller.pickFile,
          icon: state.isLoadingFile
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_open),
          label: Text(
            file == null ? l10n.csvChooseFile : l10n.csvChooseAnother,
          ),
        ),
        if (file != null && table != null) ...[
          const SizedBox(height: AppSpace.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: AutoDirectionText(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${l10n.csvRecordCount(table.records.length)} · '
              '${l10n.csvEncoding(encodingName(table.encoding))}',
            ),
          ),
          DropdownButtonFormField<String?>(
            key: const Key('csv.delimiter'),
            initialValue: state.delimiterOverride,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.csvDelimiterLabel),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  '${l10n.csvDelimiterAuto} — ${delimiterName(table.delimiter)}',
                ),
              ),
              for (final d in const [',', ';', '\t', '|'])
                DropdownMenuItem<String?>(
                  value: d,
                  child: Text(delimiterName(d)),
                ),
            ],
            onChanged: state.isImporting ? null : controller.setDelimiter,
          ),
        ],
        if (state.fileError != null) ...[
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            key: const Key('csv.fileError'),
            tone: StatusTone.danger,
            message: errorMessage(l10n, state.fileError!),
          ),
        ],
      ],
    );
  }
}

class _ColumnsSection extends StatelessWidget {
  const _ColumnsSection({
    required this.table,
    required this.mapping,
    required this.controller,
  });

  final CsvTable table;
  final ColumnMapping mapping;
  final CsvImportController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dataRecords =
        (mapping.hasHeader ? table.records.skip(1) : table.records)
            .take(3)
            .toList();

    String fieldName(ImportField field) => switch (field) {
      ImportField.ignore => l10n.csvFieldIgnore,
      ImportField.original => l10n.csvFieldOriginal,
      ImportField.meaning => l10n.csvFieldMeaning,
      ImportField.lemma => l10n.csvFieldLemma,
      ImportField.partOfSpeech => l10n.csvFieldPartOfSpeech,
      ImportField.exampleSentence => l10n.csvFieldExample,
      ImportField.exampleTranslation => l10n.csvFieldExampleTranslation,
      ImportField.grammarInfo => l10n.csvFieldGrammar,
      ImportField.notes => l10n.csvFieldNotes,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('csv.hasHeader'),
          contentPadding: EdgeInsets.zero,
          value: mapping.hasHeader,
          onChanged: controller.setHasHeader,
          title: Text(l10n.csvHasHeader),
        ),
        for (var column = 0; column < table.columnCount; column++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      mapping.hasHeader &&
                              table.records.first.cell(column).trim().isNotEmpty
                          ? '${l10n.csvColumnLabel(column + 1)}: '
                                '${table.records.first.cell(column).trim()}'
                          : l10n.csvColumnLabel(column + 1),
                      style: theme.textTheme.titleSmall,
                    ),
                    for (final record in dataRecords)
                      if (record.cell(column).trim().isNotEmpty)
                        AutoDirectionText(
                          record.cell(column).trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.germanBody.copyWith(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    const SizedBox(height: AppSpace.sm),
                    DropdownButtonFormField<ImportField>(
                      key: Key('csv.column.$column'),
                      initialValue: mapping.fieldOf(column),
                      isExpanded: true,
                      items: [
                        for (final field in ImportField.values)
                          DropdownMenuItem(
                            value: field,
                            child: Text(fieldName(field)),
                          ),
                      ],
                      onChanged: (field) => controller.setField(
                        column,
                        field ?? ImportField.ignore,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!mapping.hasOriginal) ...[
          InfoBanner(
            tone: StatusTone.danger,
            message: l10n.csvMappingNeedsWord,
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(
          l10n.csvMeaningSplitHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StrategySection extends StatelessWidget {
  const _StrategySection({required this.strategy, required this.onChanged});

  final DuplicateStrategy strategy;
  final ValueChanged<DuplicateStrategy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return RadioGroup<DuplicateStrategy>(
      groupValue: strategy,
      onChanged: (value) => onChanged(value ?? strategy),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, title, description) in [
            (
              DuplicateStrategy.skip,
              l10n.csvStrategySkip,
              l10n.csvStrategySkipDescription,
            ),
            (
              DuplicateStrategy.mergeMeanings,
              l10n.csvStrategyMerge,
              l10n.csvStrategyMergeDescription,
            ),
            (
              DuplicateStrategy.keepSeparate,
              l10n.csvStrategySeparate,
              l10n.csvStrategySeparateDescription,
            ),
          ])
            RadioListTile<DuplicateStrategy>(
              key: Key('csv.strategy.${value.name}'),
              contentPadding: EdgeInsets.zero,
              value: value,
              title: Text(title),
              subtitle: Text(description),
            ),
          Text(
            l10n.csvStrategyNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.analysis});

  final CsvImportAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lineOfRow = {for (final r in analysis.rows) r.rowNumber: r.line};
    final invalid = analysis.invalidRows;
    final valid = analysis.rows.where((r) => r.isValid).toList();

    String issueText(ImportRowIssue issue) => switch (issue) {
      ImportRowIssue.missingWord => l10n.csvRowIssueMissingWord,
      ImportRowIssue.wordTooLong => l10n.csvRowIssueWordTooLong,
      ImportRowIssue.meaningTooLong => l10n.csvRowIssueMeaningTooLong,
      ImportRowIssue.tooManyMeanings => l10n.csvRowIssueTooManyMeanings,
      ImportRowIssue.fieldTooLong => l10n.csvRowIssueFieldTooLong,
    };

    (String, StatusTone) statusOf(ImportDecision? decision) =>
        switch (decision) {
          CreateDecision() => (l10n.csvRowNew, StatusTone.success),
          MergeIntoEntryDecision() => (l10n.csvRowMerge, StatusTone.warning),
          MergeIntoRowDecision(:final targetRowNumber) => (
            l10n.csvRowMergeInFile(lineOfRow[targetRowNumber] ?? 0),
            StatusTone.warning,
          ),
          SkipDecision(reason: SkipReason.redundant, :final targetRowNumber?) =>
            (
              l10n.csvRowRedundantInFile(lineOfRow[targetRowNumber] ?? 0),
              StatusTone.neutral,
            ),
          SkipDecision(reason: SkipReason.redundant) => (
            l10n.csvRowRedundant,
            StatusTone.neutral,
          ),
          SkipDecision(:final targetRowNumber?) => (
            l10n.csvRowExistsInFile(lineOfRow[targetRowNumber] ?? 0),
            StatusTone.neutral,
          ),
          SkipDecision() => (l10n.csvRowExists, StatusTone.neutral),
          null => ('', StatusTone.neutral),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(
              key: const Key('csv.count.new'),
              tone: StatusTone.success,
              icon: Icons.add,
              label: l10n.csvCountNew(analysis.createCount),
            ),
            StatusBadge(
              key: const Key('csv.count.merge'),
              tone: StatusTone.warning,
              icon: Icons.merge_type,
              label: l10n.csvCountMerge(analysis.mergeCount),
            ),
            StatusBadge(
              key: const Key('csv.count.skip'),
              tone: StatusTone.neutral,
              icon: Icons.copy_all_outlined,
              label: l10n.csvCountSkip(analysis.skipCount),
            ),
            StatusBadge(
              key: const Key('csv.count.error'),
              tone: analysis.errorCount > 0
                  ? StatusTone.danger
                  : StatusTone.neutral,
              icon: Icons.error_outline,
              label: l10n.csvCountError(analysis.errorCount),
            ),
          ],
        ),
        if (analysis.rows.isEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.csvFormatNoDataRows),
        ],
        if (invalid.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            l10n.csvErrorsTitle(invalid.length),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          for (final row in invalid.take(_previewLimit))
            ListTile(
              key: Key('csv.error.${row.line}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                '${l10n.csvRowLine(row.line)}: '
                '${row.issues.map(issueText).join('، ')}',
              ),
              subtitle: row.draft.original.isEmpty
                  ? null
                  : AutoDirectionText(row.draft.original, maxLines: 1),
            ),
          if (invalid.length > _previewLimit)
            Text(l10n.csvMoreRows(invalid.length - _previewLimit)),
        ],
        const SizedBox(height: AppSpace.lg),
        for (final row in valid.take(_previewLimit))
          Builder(
            builder: (context) {
              final (status, tone) = statusOf(
                analysis.decisions[row.rowNumber],
              );
              return Padding(
                key: Key('csv.row.${row.line}'),
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        l10n.csvRowLine(row.line),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AutoDirectionText(
                            row.draft.original,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.wordTitle.copyWith(
                              fontSize: 17,
                            ),
                          ),
                          if (row.draft.meanings.isNotEmpty)
                            AutoDirectionText(
                              row.draft.meanings.map((m) => m.text).join('، '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (status.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xs),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: StatusBadge(label: status, tone: tone),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (valid.length > _previewLimit)
          Text(l10n.csvMoreRows(valid.length - _previewLimit)),
      ],
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({
    required this.analysis,
    required this.enabled,
    required this.importing,
    required this.onPressed,
  });

  final CsvImportAnalysis? analysis;
  final bool enabled;
  final bool importing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = analysis?.actionableCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('csv.import'),
          onPressed: enabled ? onPressed : null,
          child: importing
              ? const ButtonProgress()
              : Text(l10n.csvImportButton(count)),
        ),
        if (analysis != null && count == 0) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.csvNothingToImport,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.summary,
    required this.errorCount,
    required this.deckId,
    required this.onImportAnother,
  });

  final ImportSummary summary;
  final int errorCount;
  final String deckId;
  final VoidCallback onImportAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutcomeView(
      key: const Key('csv.result'),
      title: l10n.csvImportDone,
      lines: [
        OutcomeLine(
          Icons.add_circle_outline,
          l10n.csvResultCreated(summary.createdCount),
          tone: StatusTone.success,
        ),
        OutcomeLine(
          Icons.merge_type,
          l10n.csvResultMerged(summary.mergedCount),
        ),
        OutcomeLine(
          Icons.copy_all_outlined,
          l10n.csvResultSkipped(summary.skippedCount),
        ),
        if (errorCount > 0)
          OutcomeLine(
            Icons.error_outline,
            l10n.csvResultErrors(errorCount),
            tone: StatusTone.danger,
          ),
      ],
      primary: FilledButton(
        key: const Key('csv.viewDeck'),
        onPressed: () => context.go(AppRoutes.deck(deckId)),
        child: Text(l10n.csvViewDeck),
      ),
      secondary: OutlinedButton(
        onPressed: onImportAnother,
        child: Text(l10n.csvImportAnother),
      ),
    );
  }
}
