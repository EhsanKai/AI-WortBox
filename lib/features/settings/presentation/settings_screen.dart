import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          header(l10n.settingsLanguages),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(l10n.settingsSourceLanguage),
            trailing: Text(AppConfig.defaultSourceLanguage.nativeName),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.settingsDefinitionLanguage),
            trailing: Text(AppConfig.defaultDefinitionLanguage.nativeName),
          ),
          header(l10n.settingsPrivacy),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: Text(l10n.settingsPrivacyBody),
          ),
          header(l10n.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.appTagline),
          ),
        ],
      ),
    );
  }
}
