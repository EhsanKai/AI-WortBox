import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/design/tokens.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/release_notes.dart';
import 'about_providers.dart';

/// "About AI WortBox": the installed version and build, and what changed
/// in this build compared with the previous one.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final installed = ref.watch(installedVersionProvider);
    final notes = ref.watch(releaseNotesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: switch ((installed, notes)) {
        (AsyncData(value: final v), AsyncData(value: final n)) => _AboutBody(
          installed: v,
          notes: n,
        ),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => ErrorStateView(
          error: error,
          onRetry: () => ref
            ..invalidate(installedVersionProvider)
            ..invalidate(releaseNotesProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody({required this.installed, required this.notes});

  final InstalledVersion installed;
  final ReleaseNotes notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = notes.forInstalled(installed);
    final older = notes.olderThan(installed);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      children: [
        Row(
          children: [
            const BrandMark(size: 56),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appTitle,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.headlineSmall,
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
        const SizedBox(height: AppSpace.xl),
        SectionHeader(l10n.aboutInstalledTitle),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const Key('about.version'),
                leading: const Icon(Icons.verified_outlined),
                title: Text(l10n.aboutVersion),
                trailing: _Value(installed.version),
              ),
              const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
              ListTile(
                key: const Key('about.build'),
                leading: const Icon(Icons.tag),
                title: Text(l10n.aboutBuild),
                trailing: _Value(installed.buildNumber),
              ),
              if (current?.date case final date?) ...[
                const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                ListTile(
                  key: const Key('about.date'),
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.aboutReleaseDate),
                  trailing: _Value(
                    DateFormat.yMMMd(l10n.localeName).format(date),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        InfoBanner(
          key: const Key('about.installedNote'),
          icon: Icons.phone_iphone,
          message: l10n.aboutInstalledNote,
        ),
        const SizedBox(height: AppSpace.xl),
        SectionHeader(l10n.aboutChangesTitle),
        if (current == null)
          Card(
            key: const Key('about.noNotes'),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.aboutNoNotes),
            ),
          )
        else
          _ReleaseCard(
            key: const Key('about.currentNotes'),
            note: current,
            subtitle: older.isEmpty
                ? null
                : l10n.aboutComparedWith(older.first.build.toString()),
          ),
        if (older.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xl),
          SectionHeader(l10n.aboutEarlierTitle),
          for (final note in older) ...[
            _ReleaseCard(note: note, collapsed: true),
            const SizedBox(height: AppSpace.sm),
          ],
        ],
      ],
    );
  }
}

/// A version value: always left-to-right, so "1.0.0" reads correctly in
/// the RTL layout.
class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: TextDirection.ltr,
    style: Theme.of(context).textTheme.titleMedium,
  );
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    super.key,
    required this.note,
    this.subtitle,
    this.collapsed = false,
  });

  final ReleaseNote note;
  final String? subtitle;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = note.changesFor(l10n.localeName);
    final title = l10n.aboutReleaseHeading(note.version, note.build.toString());
    final list = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        0,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xxs),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(line, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (collapsed) {
      return Card(
        child: ExpansionTile(
          shape: const Border(),
          title: Text(title, style: theme.textTheme.titleSmall),
          children: [list],
        ),
      );
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(title, style: theme.textTheme.titleMedium),
            subtitle: subtitle == null ? null : Text(subtitle!),
          ),
          list,
        ],
      ),
    );
  }
}
