import 'dart:io';

import 'package:ai_wortbox/features/about/domain/release_notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// `version: 1.0.0+3` from pubspec.yaml, the source of the iOS and Android
/// version metadata.
({String version, int build}) pubspecVersion() {
  final line = File('pubspec.yaml')
      .readAsLinesSync()
      .firstWhere((l) => l.startsWith('version:'));
  final match = RegExp(r'^version:\s*([\d.]+)\+(\d+)\s*$').firstMatch(line)!;
  return (version: match[1]!, build: int.parse(match[2]!));
}

String notes(String releases) => '{"formatVersion": 1, "releases": $releases}';

void main() {
  group('bundled release notes (release gate)', () {
    final bundled = ReleaseNotes.parse(
      File(ReleaseNotes.assetPath).readAsStringSync(),
    );

    test('the file parses and lists builds newest first', () {
      expect(bundled.releases, isNotEmpty);
      final builds = bundled.releases.map((r) => r.build).toList();
      expect(builds, [...builds]..sort((a, b) => b.compareTo(a)));
    });

    test('the pubspec version and build have Persian and English notes', () {
      final current = pubspecVersion();
      final note = bundled.forInstalled(
        InstalledVersion(
          version: current.version,
          buildNumber: '${current.build}',
        ),
      );
      expect(
        note,
        isNotNull,
        reason:
            'Every release needs notes in assets/release_notes.json for '
            '${current.version}+${current.build} (docs/releases.md).',
      );
      expect(note!.changes['fa'], isNotEmpty);
      expect(note.changes['en'], isNotEmpty);
      expect(note.changes['fa']!.length, note.changes['en']!.length);
    });

    test('the pubspec build is the newest build in the notes', () {
      expect(bundled.releases.first.build, pubspecVersion().build);
    });

    test('the asset is declared in pubspec.yaml', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- ${ReleaseNotes.assetPath}'),
      );
    });
  });

  group('ReleaseNotes', () {
    const installed3 = InstalledVersion(version: '1.0.0', buildNumber: '3');
    final sample = ReleaseNotes.parse(
      notes('''[
        {"version": "1.0.0", "build": 2, "date": null,
         "changes": {"fa": ["دو"], "en": ["two"]}},
        {"version": "1.0.0", "build": 3, "date": "2026-10-20",
         "changes": {"fa": ["سه"], "en": ["three"]}}
      ]'''),
    );

    test('finds exactly the installed build and the older ones', () {
      expect(sample.forInstalled(installed3)!.changesFor('en'), ['three']);
      expect(sample.forInstalled(installed3)!.date, DateTime(2026, 10, 20));
      expect(sample.olderThan(installed3).map((r) => r.build), [2]);
    });

    test('never shows another build as the installed one', () {
      expect(
        sample.forInstalled(
          const InstalledVersion(version: '1.0.0', buildNumber: '4'),
        ),
        isNull,
      );
      expect(
        sample.forInstalled(
          const InstalledVersion(version: '1.1.0', buildNumber: '3'),
        ),
        isNull,
      );
      expect(
        sample.forInstalled(
          const InstalledVersion(version: '1.0.0', buildNumber: 'x'),
        ),
        isNull,
      );
    });

    test('falls back to English for an unknown language', () {
      expect(sample.forInstalled(installed3)!.changesFor('de'), ['three']);
      expect(sample.forInstalled(installed3)!.changesFor('fa'), ['سه']);
    });

    test('rejects malformed files', () {
      for (final bad in [
        '[]',
        '{"formatVersion": 2, "releases": []}',
        '{"formatVersion": 1}',
        notes('[{"version": "1.0.0", "changes": {"en": ["x"]}}]'),
        notes('[{"version": "1.0.0", "build": 3, "changes": {}}]'),
        notes('[{"version": "1.0.0", "build": 3, "changes": {"en": [""]}}]'),
        notes(
          '[{"version": "1.0.0", "build": 3, "date": "soon", '
          '"changes": {"en": ["x"]}}]',
        ),
        notes(
          '[{"version": "1.0.0", "build": 3, "changes": {"en": ["x"]}},'
          '{"version": "1.0.0", "build": 3, "changes": {"en": ["y"]}}]',
        ),
      ]) {
        expect(
          () => ReleaseNotes.parse(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });
  });
}
