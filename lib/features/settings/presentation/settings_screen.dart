import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/action_tile.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../about/presentation/about_providers.dart';
import '../../enrichment/presentation/ai_settings_controller.dart';
import '../../reminders/presentation/reminder_controller.dart';
import '../../review/presentation/practice_screen.dart';
import '../../review/presentation/review_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const sectionGap = SizedBox(height: AppSpace.xl);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxl,
        ),
        children: [
          SectionHeader(l10n.settingsLanguages),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(l10n.settingsSourceLanguage),
                  trailing: Text(AppConfig.defaultSourceLanguage.nativeName),
                ),
                const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(l10n.settingsDefinitionLanguage),
                  trailing: Text(
                    AppConfig.defaultDefinitionLanguage.nativeName,
                  ),
                ),
              ],
            ),
          ),
          sectionGap,
          SectionHeader(l10n.settingsAi),
          ActionTile(
            key: const Key('settings.ai'),
            icon: Icons.auto_awesome_outlined,
            title: 'OpenRouter',
            description: ref.watch(aiConfiguredProvider)
                ? l10n.settingsAiConfigured
                : l10n.settingsAiNotConfigured,
            onTap: () => context.go(AppRoutes.aiSettings),
          ),
          sectionGap,
          SectionHeader(l10n.settingsStudy),
          ActionTile(
            key: const Key('settings.reviewDirection'),
            icon: Icons.swap_horiz,
            title: l10n.reviewDirectionTitle,
            description: switch (ref.watch(reviewDirectionProvider).value) {
              final d? => reviewDirectionLabel(l10n, d),
              null => '',
            },
            onTap: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    0,
                    AppSpace.gutter,
                    AppSpace.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(l10n.reviewDirectionTitle),
                      const ReviewDirectionPicker(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionTile(
            key: const Key('settings.reminder'),
            icon: Icons.notifications_outlined,
            title: l10n.reminderTitle,
            description: switch (ref.watch(reminderControllerProvider).value) {
              final r? when r.enabled => l10n.reminderOnAt(
                MaterialLocalizations.of(context)
                    .formatTimeOfDay(TimeOfDay(hour: r.hour, minute: r.minute)),
              ),
              _ => l10n.reminderOff,
            },
            onTap: () => context.go(AppRoutes.reminders),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionTile(
            key: const Key('settings.tags'),
            icon: Icons.label_outline,
            title: l10n.tagsTitle,
            description: l10n.tagsSettingsDescription,
            onTap: () => context.push(AppRoutes.tags),
          ),
          sectionGap,
          SectionHeader(l10n.settingsData),
          ActionTile(
            key: const Key('settings.backup'),
            icon: Icons.settings_backup_restore,
            title: l10n.backupTitle,
            description: l10n.backupTileDescription,
            onTap: () => context.go(AppRoutes.backup),
          ),
          sectionGap,
          SectionHeader(l10n.settingsPrivacy),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsPrivacyBody),
            ),
          ),
          sectionGap,
          SectionHeader(l10n.settingsAbout),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                children: [
                  const BrandMark(size: 48),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          l10n.appTagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionTile(
            key: const Key('settings.about'),
            icon: Icons.info_outline,
            title: l10n.aboutTitle,
            description: switch (ref.watch(installedVersionProvider).value) {
              final v? => l10n.aboutTileVersion(v.version, v.buildNumber),
              null => l10n.aboutTileDescription,
            },
            onTap: () => context.go(AppRoutes.about),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionTile(
            key: const Key('settings.licenses'),
            icon: Icons.description_outlined,
            title: l10n.settingsLicenses,
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationIcon: const Padding(
                padding: EdgeInsets.all(AppSpace.sm),
                child: BrandMark(size: 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
