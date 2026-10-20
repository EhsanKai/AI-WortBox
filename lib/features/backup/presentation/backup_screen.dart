import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../app/providers.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/tokens.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/outcome_view.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup_codec.dart' show BackupCounts;
import '../data/backup_service.dart';
import 'backup_controller.dart';

/// Settings → Backup and restore.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(backupControllerProvider);
    final controller = ref.read(backupControllerProvider.notifier);
    ref.listen(backupControllerProvider, (_, next) {
      if (next is BackupIdle && next.saved) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.backupSaved)));
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: switch (state) {
        BackupBusy(:final task) => LoadingView(
          message: switch (task) {
            BackupTask.saving => l10n.backupBusySaving,
            BackupTask.reading => l10n.backupBusyReading,
            BackupTask.restoring => l10n.backupBusyRestoring,
          },
        ),
        BackupPreview() => _PreviewView(preview: state),
        BackupRestored(:final result) => _ResultView(result: result),
        BackupIdle() || BackupFailed() => _HomeView(
          error: state is BackupFailed ? state.error : null,
          onDismissError: controller.reset,
        ),
      },
    );
  }
}

class _HomeView extends ConsumerWidget {
  const _HomeView({this.error, required this.onDismissError});

  final Object? error;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(backupControllerProvider.notifier);
    final safety = ref.watch(safetyBackupsProvider).value ?? const [];
    final error = this.error;
    return ListView(
      // A new error starts at the top, where it is shown.
      key: PageStorageKey(error == null ? 'backup.home' : 'backup.error'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        if (error != null) ...[
          InfoBanner(
            key: const Key('backup.error'),
            tone: StatusTone.danger,
            title: errorMessage(l10n, error),
            message: [
              if (error is BackupException && error.location != null)
                l10n.backupErrorLocation(error.location!),
              l10n.backupNothingChanged,
            ].join('\n'),
            action: TextButton(
              onPressed: onDismissError,
              child: Text(l10n.backupDismiss),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        Text(l10n.backupIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpace.xl),
        SectionHeader(l10n.backupSaveTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bullet(Icons.check_circle_outline, l10n.backupIncludes),
                const SizedBox(height: AppSpace.sm),
                _Bullet(Icons.block, l10n.backupExcludes),
                const SizedBox(height: AppSpace.lg),
                FilledButton.icon(
                  key: const Key('backup.save'),
                  onPressed: controller.save,
                  icon: const Icon(Icons.save_alt),
                  label: Text(l10n.backupSaveButton),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        SectionHeader(l10n.backupRestoreTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.backupRestoreIntro,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpace.lg),
                OutlinedButton.icon(
                  key: const Key('backup.pick'),
                  onPressed: controller.pick,
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.backupPickButton),
                ),
              ],
            ),
          ),
        ),
        if (safety.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Card(
            child: ListTile(
              key: const Key('backup.safetyCopy'),
              leading: const Icon(Icons.history),
              title: Text(l10n.backupSafetyCopyTitle),
              subtitle: Text(
                l10n.backupSafetyCopySaved(
                  _dateTime(context, ref, safety.first.savedAt),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => controller.openSafetyCopy(safety.first),
            ),
          ),
        ],
      ],
    );
  }
}

String _dateTime(BuildContext context, WidgetRef ref, DateTime utc) {
  final l10n = AppLocalizations.of(context);
  final local = ref.read(clockProvider).toLocal(utc);
  return '${DateFormat.yMMMd(l10n.localeName).format(local)} '
      '${DateFormat.Hm(l10n.localeName).format(local)}';
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _PreviewView extends ConsumerWidget {
  const _PreviewView({required this.preview});

  final BackupPreview preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(backupControllerProvider.notifier);
    final manifest = preview.backup.manifest;
    final file = manifest.counts;
    final device = preview.current;
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    final exported = _dateTime(context, ref, manifest.exportedAt);

    TableRow row(String label, int inFile, int onDevice) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Text(label),
        ),
        Text(numbers.format(inFile), textAlign: TextAlign.end),
        Text(numbers.format(onDevice), textAlign: TextAlign.end),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        SectionHeader(l10n.backupPreviewTitle),
        Card(
          key: const Key('backup.preview'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.backupPreviewExported(exported),
                  style: theme.textTheme.titleSmall,
                ),
                if (manifest.appVersion != null)
                  Text(
                    l10n.backupPreviewApp(
                      manifest.appVersion!,
                      manifest.appBuild ?? '?',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                if (preview.fromSafetyCopy) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    l10n.backupPreviewSafetyCopy,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                  },
                  children: [
                    TableRow(
                      children: [
                        const SizedBox.shrink(),
                        Text(
                          l10n.backupColumnFile,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          l10n.backupColumnDevice,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    row(l10n.backupCountDecks, file.decks, device.decks),
                    row(l10n.backupCountWords, file.entries, device.entries),
                    row(
                      l10n.backupCountCards,
                      file.flashcards,
                      device.flashcards,
                    ),
                    row(
                      l10n.backupCountReviews,
                      file.reviewEvents,
                      device.reviewEvents,
                    ),
                    row(l10n.backupCountTags, file.tags, device.tags),
                    row(
                      l10n.backupCountSentences,
                      file.sentencePractice,
                      device.sentencePractice,
                    ),
                    row(
                      l10n.backupCountAppearances,
                      file.cardAppearances,
                      device.cardAppearances,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        SectionHeader(l10n.backupChooseHow),
        _ModeCard(
          icon: Icons.playlist_add,
          title: l10n.backupMergeTitle,
          body: l10n.backupMergeBody,
          button: FilledButton.icon(
            key: const Key('backup.merge'),
            onPressed: () => controller.restore(RestoreMode.merge),
            icon: const Icon(Icons.playlist_add),
            label: Text(l10n.backupMergeButton),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _ModeCard(
          icon: Icons.restore,
          title: l10n.backupReplaceTitle,
          body: l10n.backupReplaceBody,
          danger: true,
          button: OutlinedButton.icon(
            key: const Key('backup.replace'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.danger.foreground,
            ),
            onPressed: () async {
              if (await _confirmReplace(context, device, exported)) {
                await controller.restore(RestoreMode.replace);
              }
            },
            icon: const Icon(Icons.warning_amber_rounded),
            label: Text(l10n.backupReplaceButton),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        TextButton(
          key: const Key('backup.cancelPreview'),
          onPressed: controller.reset,
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  }

  Future<bool> _confirmReplace(
    BuildContext context,
    BackupCounts device,
    String exported,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: context.colors.danger.foreground,
        ),
        title: Text(l10n.backupReplaceConfirmTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.backupReplaceConfirmBody(
              device.entries,
              device.decks,
              exported,
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('backup.replaceCancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('backup.replaceConfirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.danger.foreground,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupReplaceConfirm),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.button,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget button;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger
        ? context.colors.danger.foreground
        : theme.colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpace.md),
            button,
          ],
        ),
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.result});

  final RestoreResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final r = result;
    return OutcomeView(
      key: const Key('backup.result'),
      title: r.mode == RestoreMode.merge
          ? l10n.backupDoneMergeTitle
          : l10n.backupDoneReplaceTitle,
      lines: [
        OutcomeLine(Icons.translate, l10n.backupResultWords(r.entriesAdded)),
        if (r.entriesAlreadyPresent > 0)
          OutcomeLine(
            Icons.done_all,
            l10n.backupResultPresent(r.entriesAlreadyPresent),
          ),
        OutcomeLine(
          Icons.inventory_2_outlined,
          l10n.backupResultDecks(r.decksAdded),
        ),
        OutcomeLine(
          Icons.event_repeat,
          l10n.backupResultCards(r.flashcardsAdded),
        ),
        if (r.flashcardsKept > 0)
          OutcomeLine(
            Icons.lock_clock_outlined,
            l10n.backupResultCardsKept(r.flashcardsKept),
          ),
        OutcomeLine(
          Icons.history,
          l10n.backupResultReviews(r.reviewEventsAdded),
        ),
        OutcomeLine(
          Icons.shield_outlined,
          l10n.backupResultSafety,
          tone: StatusTone.success,
        ),
      ],
      primary: FilledButton(
        key: const Key('backup.done'),
        onPressed: ref.read(backupControllerProvider.notifier).reset,
        child: Text(l10n.backupDone),
      ),
    );
  }
}
