import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../features/about/presentation/about_screen.dart';
import '../features/add_vocabulary/presentation/add_vocabulary_screen.dart';
import '../features/backup/presentation/backup_screen.dart';
import '../features/csv_import/presentation/csv_import_screen.dart';
import '../features/dashboard/presentation/today_screen.dart';
import '../features/decks/presentation/deck_detail_screen.dart';
import '../features/decks/presentation/decks_screen.dart';
import '../features/enrichment/presentation/ai_settings_screen.dart';
import '../features/enrichment/presentation/enrichment_screen.dart';
import '../features/reminders/presentation/reminder_screen.dart';
import '../features/review/presentation/memory_coach_screen.dart';
import '../features/review/presentation/practice_controller.dart';
import '../features/review/presentation/practice_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/sentence_practice/domain/sentence_practice.dart';
import '../features/sentence_practice/presentation/sentence_practice_controller.dart';
import '../features/sentence_practice/presentation/sentence_practice_session_screen.dart';
import '../features/sentence_practice/presentation/sentence_practice_setup_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/tags/presentation/tags_screen.dart';
import '../features/vocabulary/presentation/entry_detail_screen.dart';
import '../features/vocabulary/presentation/vocabulary_form_screen.dart';
import '../features/vocabulary/presentation/vocabulary_search_screen.dart';
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
  static const aiSettings = '$settings/ai';
  static const reminders = '$settings/reminder';
  static const about = '$settings/about';
  static const backup = '$settings/backup';
  static const ankiImport = '$add/anki';
  static const search = '$words/search';
  static const tags = '$words/tags';
  static const practice = '$today/practice';

  /// The Memory Coach: words that need practice.
  static const memoryCoach = '$today/coach';

  /// AI sentence practice (not scheduled review).
  static const sentencePractice = '$today/sentences';

  static String sentenceSession(SentenceSessionConfig c) => Uri(
    path: '$sentencePractice/session',
    queryParameters: {
      'direction': c.direction.name,
      'level': c.level.name,
      'size': '${c.size}',
      'deckId': ?c.deckId,
      'tagId': ?c.tagId,
    },
  ).toString();

  /// Reads [sentenceSession]'s parameters; unknown values fall back to the
  /// defaults.
  static SentenceSessionConfig sentenceConfigFrom(Map<String, String> q) {
    const defaults = SentenceSessionConfig();
    T byName<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    final size = int.tryParse(q['size'] ?? '');
    return SentenceSessionConfig(
      direction: byName(
        SentencePracticeDirection.values,
        q['direction'],
        defaults.direction,
      ),
      level: byName(SentenceLevel.values, q['level'], defaults.level),
      size: AppConfig.sentencePracticeSizes.contains(size)
          ? size!
          : defaults.size,
      deckId: q['deckId'],
      tagId: q['tagId'],
    );
  }

  /// A scheduled (FSRS) review session, or free practice with [free],
  /// [difficultOnly] or [coach] (the Memory Coach's words).
  static String practiceSession({
    String? deckId,
    bool difficultOnly = false,
    bool free = false,
    bool coach = false,
  }) => Uri(
    path: '$practice/session',
    queryParameters: {
      'deckId': ?deckId,
      if (difficultOnly) 'difficult': '1',
      if (free) 'free': '1',
      if (coach) 'coach': '1',
    },
  ).toString();

  static String deck(String id) => '$words/decks/${Uri.encodeComponent(id)}';

  static String newEntry(String deckId) => '${deck(deckId)}/entries/new';

  static String deckImport(String deckId) => '${deck(deckId)}/import';

  static String deckScan(String deckId) => '${deck(deckId)}/scan';

  static String deckEnrich(String deckId) => '${deck(deckId)}/enrich';

  /// AI meanings for words selected in a list; the entry ids go in `extra`.
  static const enrichSelection = '$words/enrich';

  static String entryEnrich(String deckId, String entryId) =>
      '${entry(deckId, entryId)}/enrich';

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
              routes: [
                GoRoute(
                  path: 'practice',
                  builder: (_, _) => const PracticeSetupScreen(),
                  routes: [
                    GoRoute(
                      path: 'session',
                      builder: (_, state) => PracticeSessionScreen(
                        config: PracticeConfig(
                          deckId: state.uri.queryParameters['deckId'],
                          difficultOnly:
                              state.uri.queryParameters['difficult'] == '1',
                          scheduled: state.uri.queryParameters['free'] != '1',
                          coach: state.uri.queryParameters['coach'] == '1',
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'coach',
                  builder: (_, _) => const MemoryCoachScreen(),
                ),
                GoRoute(
                  path: 'sentences',
                  builder: (_, _) => const SentencePracticeSetupScreen(),
                  routes: [
                    GoRoute(
                      path: 'session',
                      builder: (_, state) => SentencePracticeSessionScreen(
                        config: AppRoutes.sentenceConfigFrom(
                          state.uri.queryParameters,
                        ),
                      ),
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
              path: AppRoutes.words,
              builder: (_, _) => const DecksScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (_, _) => const VocabularySearchScreen(),
                ),
                GoRoute(path: 'tags', builder: (_, _) => const TagsScreen()),
                GoRoute(
                  path: 'enrich',
                  builder: (_, state) => EnrichmentScreen.selection(
                    entryIds: switch (state.extra) {
                      final List<Object?> ids =>
                        ids.whereType<String>().toList(),
                      _ => const [],
                    },
                  ),
                ),
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
                      path: 'enrich',
                      builder: (_, state) => EnrichmentScreen(
                        deckId: state.pathParameters['deckId']!,
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
                          path: 'enrich',
                          builder: (_, state) => EnrichmentScreen(
                            deckId: state.pathParameters['deckId']!,
                            entryId: state.pathParameters['entryId'],
                          ),
                        ),
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
                GoRoute(
                  path: 'anki',
                  builder: (_, state) => CsvImportScreen(
                    initialDeckId: state.uri.queryParameters['deckId'],
                    anki: true,
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
              routes: [
                GoRoute(
                  path: 'ai',
                  builder: (_, _) => const AiSettingsScreen(),
                ),
                GoRoute(
                  path: 'reminder',
                  builder: (_, _) => const ReminderScreen(),
                ),
                GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
                GoRoute(
                  path: 'backup',
                  builder: (_, _) => const BackupScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Icon(Icons.link_off, size: 48))),
);
