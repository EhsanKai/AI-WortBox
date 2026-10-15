import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Entry point for the three ways of adding vocabulary. The actions are
/// enabled in Phase 2 (CSV, manual) and Phase 3 (scan).
class AddVocabularyScreen extends StatelessWidget {
  const AddVocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAdd)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.addSubtitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _AddAction(
            icon: Icons.upload_file_outlined,
            title: l10n.addImportCsv,
            description: l10n.addImportCsvDescription,
          ),
          const SizedBox(height: 8),
          _AddAction(
            icon: Icons.edit_note,
            title: l10n.addManual,
            description: l10n.addManualDescription,
          ),
          const SizedBox(height: 8),
          _AddAction(
            icon: Icons.document_scanner_outlined,
            title: l10n.addScan,
            description: l10n.addScanDescription,
          ),
        ],
      ),
    );
  }
}

class _AddAction extends StatelessWidget {
  const _AddAction({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card.outlined(
      child: ListTile(
        enabled: false,
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(description),
        trailing: Chip(label: Text(l10n.comingSoon)),
      ),
    );
  }
}
