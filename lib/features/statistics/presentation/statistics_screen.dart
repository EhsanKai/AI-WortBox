import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';

/// Learning statistics. Populated in Phase 5 once reviews exist.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navStatistics)),
      body: EmptyStateView(
        icon: Icons.insights_outlined,
        title: l10n.statisticsEmpty,
      ),
    );
  }
}
