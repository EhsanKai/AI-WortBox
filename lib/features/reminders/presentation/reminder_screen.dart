import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_colors.dart' show StatusTone;
import '../../../core/design/tokens.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/reminder.dart';
import 'reminder_controller.dart';

/// Turn the daily study reminder on or off and choose its time.
class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  bool _busy = false;
  Object? _error;

  ReminderController get _controller =>
      ref.read(reminderControllerProvider.notifier);

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime(ReminderSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;
    await _run(() => _controller.setTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(reminderControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reminderTitle)),
      body: switch (settings) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.sm,
            AppSpace.gutter,
            AppSpace.xxl,
          ),
          children: [
            Text(
              l10n.reminderIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpace.lg),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('reminder.enabled'),
                    value: value.enabled,
                    title: Text(l10n.reminderEnabled),
                    secondary: const Icon(Icons.notifications_outlined),
                    onChanged: _busy
                        ? null
                        : (on) => _run(
                            on ? _controller.enable : _controller.disable,
                          ),
                  ),
                  const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                  ListTile(
                    key: const Key('reminder.time'),
                    enabled: !_busy,
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.reminderTime),
                    trailing: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay(hour: value.hour, minute: value.minute),
                      ),
                      key: const Key('reminder.timeValue'),
                    ),
                    onTap: () => _pickTime(value),
                  ),
                ],
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: AppSpace.md),
              InfoBanner(
                key: const Key('reminder.error'),
                tone: StatusTone.danger,
                message: errorMessage(AppLocalizations.of(context), error),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            InfoBanner(icon: Icons.info_outline, message: l10n.reminderNote),
          ],
        ),
        AsyncError(:final error) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(reminderControllerProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}
