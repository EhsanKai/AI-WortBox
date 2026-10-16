import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/add_vocabulary/presentation/add_vocabulary_screen.dart';
import '../features/csv_import/presentation/csv_import_screen.dart';
import '../features/dashboard/presentation/today_screen.dart';
import '../features/decks/presentation/deck_detail_screen.dart';
import '../features/decks/presentation/decks_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/vocabulary/presentation/entry_detail_screen.dart';
import '../features/vocabulary/presentation/vocabulary_form_screen.dart';
import 'shell.dart';

abstract final class AppRoutes {
  static const today = '/today';
  static const words = '/words';
  static const add = '/add';
  static const statistics = '/statistics';
  static const settings = '/settings';

  static const manualEntry = '$add/manual';
  static const csvImport = '$add/csv';
  static const scan = '$add/scan';

  static String deck(String id) => '$words/decks/${Uri.encodeComponent(id)}';

  static String newEntry(String deckId) => '${deck(deckId)}/entries/new';

  static String deckImport(String deckId) => '${deck(deckId)}/import';

  static String deckScan(String deckId) => '${deck(deckId)}/scan';

  static String entry(String deckId, String entryId) =>
      '${deck(deckId)}/entries/${Uri.encodeComponent(entryId)}';

  static String editEntry(String deckId, String entryId) =>
      '${entry(deckId, entryId)}/edit';
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
                  routes: [
                    GoRoute(
                      path: 'scan',
                      builder: (_, state) => ScanScreen(
                        initialDeckId: state.pathParameters['deckId'],
                      ),
                    ),
                    GoRoute(
                      path: 'import',
                      builder: (_, state) => CsvImportScreen(
                        initialDeckId: state.pathParameters['deckId'],
                      ),
                    ),
                    // Must precede 'entries/:entryId'.
                    GoRoute(
                      path: 'entries/new',
                      builder: (_, state) => VocabularyFormScreen(
                        deckId: state.pathParameters['deckId'],
                      ),
                    ),
                    GoRoute(
                      path: 'entries/:entryId',
                      builder: (_, state) => EntryDetailScreen(
                        deckId: state.pathParameters['deckId']!,
                        entryId: state.pathParameters['entryId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (_, state) => VocabularyFormScreen(
                            entryId: state.pathParameters['entryId'],
                          ),
                        ),
                      ],
                    ),
                  ],
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
              routes: [
                GoRoute(
                  path: 'manual',
                  builder: (_, state) => VocabularyFormScreen(
                    deckId: state.uri.queryParameters['deckId'],
                  ),
                ),
                GoRoute(
                  path: 'scan',
                  builder: (_, state) => ScanScreen(
                    initialDeckId: state.uri.queryParameters['deckId'],
                  ),
                ),
                GoRoute(
                  path: 'csv',
                  builder: (_, state) => CsvImportScreen(
                    initialDeckId: state.uri.queryParameters['deckId'],
                  ),
                ),
              ],
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
