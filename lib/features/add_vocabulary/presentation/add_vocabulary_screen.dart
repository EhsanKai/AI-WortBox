import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';

/// Entry point for the three ways of adding vocabulary.
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
            key: const Key('add.csv'),
            icon: Icons.upload_file_outlined,
            title: l10n.addImportCsv,
            description: l10n.addImportCsvDescription,
            onTap: () => context.go(AppRoutes.csvImport),
          ),
          const SizedBox(height: 8),
          _AddAction(
            key: const Key('add.manual'),
            icon: Icons.edit_note,
            title: l10n.addManual,
            description: l10n.addManualDescription,
            onTap: () => context.go(AppRoutes.manualEntry),
          ),
          const SizedBox(height: 8),
          _AddAction(
            key: const Key('add.scan'),
            icon: Icons.document_scanner_outlined,
            title: l10n.addScan,
            description: l10n.addScanDescription,
            onTap: () => context.go(AppRoutes.scan),
          ),
        ],
      ),
    );
  }
}

class _AddAction extends StatelessWidget {
  const _AddAction({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.chevron_left
              : Icons.chevron_right,
        ),
      ),
    );
  }
}
