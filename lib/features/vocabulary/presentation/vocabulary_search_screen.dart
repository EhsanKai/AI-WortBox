import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'vocabulary_browser.dart';

/// Search and filters across every deck.
class VocabularySearchScreen extends StatelessWidget {
  const VocabularySearchScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).searchAllTitle)),
    body: const VocabularyBrowser(),
  );
}
