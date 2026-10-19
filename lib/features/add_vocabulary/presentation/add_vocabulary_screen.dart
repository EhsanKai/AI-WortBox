import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/widgets/action_tile.dart';
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
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxl,
        ),
        children: [
          Text(l10n.addSubtitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.lg),
          ActionTile(
            key: const Key('add.csv'),
            icon: Icons.upload_file_outlined,
            title: l10n.addImportCsv,
            description: l10n.addImportCsvDescription,
            onTap: () => context.go(AppRoutes.csvImport),
          ),
          const SizedBox(height: AppSpace.md),
          ActionTile(
            key: const Key('add.manual'),
            icon: Icons.edit_note,
            title: l10n.addManual,
            description: l10n.addManualDescription,
            onTap: () => context.go(AppRoutes.manualEntry),
          ),
          const SizedBox(height: AppSpace.md),
          ActionTile(
            key: const Key('add.anki'),
            icon: Icons.style_outlined,
            title: l10n.ankiImportTitle,
            description: l10n.ankiImportDescription,
            onTap: () => context.go(AppRoutes.ankiImport),
          ),
          const SizedBox(height: AppSpace.md),
          ActionTile(
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
