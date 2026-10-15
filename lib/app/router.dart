import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/add_vocabulary/presentation/add_vocabulary_screen.dart';
import '../features/dashboard/presentation/today_screen.dart';
import '../features/decks/presentation/deck_detail_screen.dart';
import '../features/decks/presentation/decks_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import 'shell.dart';

abstract final class AppRoutes {
  static const today = '/today';
  static const words = '/words';
  static const add = '/add';
  static const statistics = '/statistics';
  static const settings = '/settings';

  static String deck(String id) => '$words/decks/${Uri.encodeComponent(id)}';
}

GoRouter createRouter({String initialLocation = AppRoutes.today}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.today,
              builder: (_, _) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.words,
              builder: (_, _) => const DecksScreen(),
              routes: [
                GoRoute(
                  path: 'decks/:deckId',
                  builder: (_, state) =>
                      DeckDetailScreen(deckId: state.pathParameters['deckId']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.add,
              builder: (_, _) => const AddVocabularyScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.statistics,
              builder: (_, _) => const StatisticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, _) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Icon(Icons.link_off, size: 48))),
);
