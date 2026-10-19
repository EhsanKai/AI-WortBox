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
import '../data/request_scheduler.dart';
import '../domain/ai_model_catalog.dart';
import '../domain/free_model_policy.dart';
import 'free_usage_controller.dart';

/// Free-only mode, routing mode, models, words per request, the free daily
/// quota, rate-limit status and cache statistics.
class FreeUsageSection extends ConsumerStatefulWidget {
  const FreeUsageSection({super.key, required this.paidModel});

  /// The catalog model used when free-only mode is off.
  final String paidModel;

  @override
  ConsumerState<FreeUsageSection> createState() => _FreeUsageSectionState();
}

class _FreeUsageSectionState extends ConsumerState<FreeUsageSection> {
  bool _saveFailed = false;

  FreeUsageController get _controller =>
      ref.read(freeUsageControllerProvider.notifier);

  Future<void> _save(Future<void> Function() change) async {
    setState(() => _saveFailed = false);
    try {
      await change();
    } on StorageException {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  Future<void> _setFreeOnly(bool value) async {
    if (!value) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(l10n.aiPaidConfirmTitle),
          content: Text(l10n.aiPaidConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const Key('ai.confirmPaid'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.aiPaidConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _save(() => _controller.setFreeOnly(value));
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _controller.clearCache();
    } on StorageException {
      if (mounted) setState(() => _saveFailed = true);
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.aiCacheCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(freeUsageControllerProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.nowUtc();
    String time(DateTime utc) {
      final local = clock.toLocal(utc);
      final today = clock.toLocal(now);
      final sameDay =
          local.year == today.year &&
          local.month == today.month &&
          local.day == today.day;
      return (sameDay
              ? intl.DateFormat.Hm(l10n.localeName)
              : intl.DateFormat.MMMd(l10n.localeName).add_Hm())
          .format(local);
    }

    String label(String id) => AiModelCatalog.byId(id)?.label ?? id;
    const gap = SizedBox(height: AppSpace.md);

    final children = switch (async) {
      AsyncData(:final value) => <Widget>[
        SwitchListTile(
          key: const Key('ai.freeOnly'),
          contentPadding: EdgeInsets.zero,
          value: value.preferences.freeOnly,
          onChanged: _setFreeOnly,
          title: Text(l10n.aiFreeOnly),
          subtitle: Text(
            value.preferences.freeOnly ? l10n.aiFreeOnlyOn : l10n.aiFreeOnlyOff,
          ),
        ),
        if (value.preferences.freeOnly) ...[
          gap,
          SegmentedButton<FreeRoutingMode>(
            key: const Key('ai.routing'),
            segments: [
              ButtonSegment(
                value: FreeRoutingMode.autoFree,
                label: Text(l10n.aiRoutingAuto),
              ),
              ButtonSegment(
                value: FreeRoutingMode.qualityFree,
                label: Text(l10n.aiRoutingQuality),
              ),
            ],
            selected: {value.preferences.mode},
            onSelectionChanged: (s) =>
                _save(() => _controller.setMode(s.single)),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            value.preferences.mode == FreeRoutingMode.autoFree
                ? l10n.aiRoutingAutoHelp
                : l10n.aiRoutingQualityHelp,
            style: theme.textTheme.bodySmall,
          ),
          if (value.qualityUnverified) ...[
            const SizedBox(height: AppSpace.sm),
            InfoBanner(
              key: const Key('ai.qualityUnverified'),
              tone: StatusTone.warning,
              message: l10n.aiQualityUnverified,
            ),
          ] else if (value.preferences.mode == FreeRoutingMode.qualityFree &&
              value.catalog != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.aiFreeModelsVerified(value.catalog!.ranked.length),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
        gap,
        Text(
          l10n.aiCurrentModel(label(value.plannedModel(widget.paidModel))),
          key: const Key('ai.currentModel'),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          value.usage.lastModelUsed == null
              ? l10n.aiLastModelNone
              : l10n.aiLastModel(label(value.usage.lastModelUsed!)),
          key: const Key('ai.lastModel'),
          style: theme.textTheme.bodySmall,
        ),
        gap,
        DropdownButtonFormField<int>(
          key: const Key('ai.batchSize'),
          initialValue: value.preferences.wordsPerRequest,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiBatchSize,
            helperText: l10n.aiBatchSizeHelp,
            helperMaxLines: 3,
          ),
          items: [
            for (var n = 1; n <= AppConfig.aiMaxWordsPerRequest; n++)
              DropdownMenuItem(
                value: n,
                child: Text(
                  intl.NumberFormat.decimalPattern(l10n.localeName).format(n),
                ),
              ),
          ],
          onChanged: (n) {
            if (n != null) _save(() => _controller.setWordsPerRequest(n));
          },
        ),
        gap,
        Text(
          switch ((
            value.usage.estimatedRemaining(now),
            value.usage.remoteLimit,
          )) {
            (final left?, final limit?) => l10n.aiQuotaRemaining(left, limit),
            (final left?, null) => l10n.aiQuotaRemainingNoLimit(left),
            _ => l10n.aiQuotaUnknown,
          },
          key: const Key('ai.quota'),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          l10n.aiQuotaSentToday(value.usage.requestsToday),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: switch (value.rate) {
            RateLimitStatus(pausedUntil: final until?) => StatusBadge(
              key: const Key('ai.rateStatus'),
              icon: Icons.pause_circle_outline,
              tone: StatusTone.warning,
              label: l10n.aiRatePaused(time(until)),
            ),
            RateLimitStatus(cooldownUntil: final until?) => StatusBadge(
              key: const Key('ai.rateStatus'),
              icon: Icons.hourglass_bottom,
              tone: StatusTone.warning,
              label: l10n.aiRateCooling(time(until)),
            ),
            _ => StatusBadge(
              key: const Key('ai.rateStatus'),
              icon: Icons.check,
              tone: StatusTone.success,
              label: l10n.aiRateReady,
            ),
          },
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.aiRatePacing(AppConfig.aiMinRequestSpacing.inSeconds),
          style: theme.textTheme.bodySmall,
        ),
        gap,
        Text(
          l10n.aiCacheStats(value.cacheCount),
          key: const Key('ai.cacheStats'),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          l10n.aiCacheUsage(value.usage.cacheHits, value.usage.cacheMisses),
          style: theme.textTheme.bodySmall,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('ai.clearCache'),
            onPressed: value.cacheCount == 0 ? null : _clearCache,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(l10n.aiCacheClear),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton.icon(
          key: const Key('ai.refreshUsage'),
          onPressed: value.refreshing ? null : _controller.refresh,
          icon: value.refreshing
              ? const ButtonProgress()
              : const Icon(Icons.refresh),
          label: Text(l10n.aiRefreshUsage),
        ),
        if (value.refreshFailed) ...[
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            key: const Key('ai.refreshFailed'),
            tone: StatusTone.danger,
            message: l10n.aiUsageRefreshFailed,
          ),
        ],
        if (_saveFailed) ...[
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            key: const Key('ai.prefsError'),
            tone: StatusTone.danger,
            message: l10n.aiPrefsSaveFailed,
          ),
        ],
      ],
      AsyncError(:final error) => [
        InfoBanner(tone: StatusTone.danger, message: errorMessage(l10n, error)),
      ],
      _ => [const LinearProgressIndicator()],
    };

    return Column(
      key: const Key('ai.free'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionHeader(l10n.aiFreeTitle), ...children],
    );
  }
}
