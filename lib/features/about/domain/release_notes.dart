import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The installed app's version metadata, read from the platform (iOS
/// `CFBundleShortVersionString`/`CFBundleVersion`, Android
/// `versionName`/`versionCode`), which the build takes from `pubspec.yaml`.
@immutable
class InstalledVersion {
  const InstalledVersion({required this.version, required this.buildNumber});

  /// E.g. `1.0.0`.
  final String version;

  /// E.g. `3`, as reported by the platform (a string on every platform).
  final String buildNumber;

  /// The build number as an integer; null when it is not one.
  int? get build => int.tryParse(buildNumber.trim());

  @override
  bool operator ==(Object other) =>
      other is InstalledVersion &&
      other.version == version &&
      other.buildNumber == buildNumber;

  @override
  int get hashCode => Object.hash(version, buildNumber);

  @override
  String toString() => '$version+$buildNumber';
}

/// The user-readable changes of one build compared with the previous one.
@immutable
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.build,
    required this.changes,
    this.date,
  });

  final String version;
  final int build;

  /// Release date, only when it is maintained accurately; otherwise null.
  final DateTime? date;

  /// Change lines per language code (`fa`, `en`).
  final Map<String, List<String>> changes;

  /// The lines for [languageCode], falling back to English, then to any
  /// language that has notes.
  List<String> changesFor(String languageCode) =>
      changes[languageCode] ??
      changes['en'] ??
      (changes.values.isEmpty ? const [] : changes.values.first);
}

/// The release notes bundled with the app (`assets/release_notes.json`),
/// newest build first. See docs/releases.md for how to maintain them.
@immutable
class ReleaseNotes {
  const ReleaseNotes(this.releases);

  /// Supported value of the file's `formatVersion`.
  static const formatVersion = 1;

  /// Asset path, also listed in `pubspec.yaml`.
  static const assetPath = 'assets/release_notes.json';

  /// Parses the asset. Throws [FormatException] when the file does not
  /// follow the documented format (tests keep the bundled file valid).
  factory ReleaseNotes.parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map || json['formatVersion'] != formatVersion) {
      throw const FormatException('Unsupported release notes format');
    }
    final list = json['releases'];
    if (list is! List) throw const FormatException('releases missing');
    final releases = <ReleaseNote>[];
    for (final item in list) {
      if (item is! Map) throw const FormatException('release is not a map');
      final version = item['version'];
      final build = item['build'];
      final rawDate = item['date'];
      final rawChanges = item['changes'];
      if (version is! String || version.isEmpty || build is! int) {
        throw const FormatException('release needs version and build');
      }
      if (rawChanges is! Map || rawChanges.isEmpty) {
        throw FormatException('release $build has no changes');
      }
      final changes = <String, List<String>>{};
      for (final MapEntry(:key, :value) in rawChanges.entries) {
        if (key is! String ||
            value is! List ||
            value.isEmpty ||
            value.any((line) => line is! String || line.trim().isEmpty)) {
          throw FormatException('release $build: invalid changes for $key');
        }
        changes[key] = List.unmodifiable(value.cast<String>());
      }
      DateTime? date;
      if (rawDate != null) {
        date = rawDate is String ? DateTime.tryParse(rawDate) : null;
        if (date == null) throw FormatException('release $build: bad date');
      }
      releases.add(
        ReleaseNote(
          version: version,
          build: build,
          date: date,
          changes: Map.unmodifiable(changes),
        ),
      );
    }
    releases.sort((a, b) => b.build.compareTo(a.build));
    for (var i = 1; i < releases.length; i++) {
      if (releases[i].build == releases[i - 1].build) {
        throw FormatException('build ${releases[i].build} listed twice');
      }
    }
    return ReleaseNotes(List.unmodifiable(releases));
  }

  /// Newest first.
  final List<ReleaseNote> releases;

  /// The notes of exactly [installed] (same version and build), or null.
  /// Notes of another build are never shown as the installed build's.
  ReleaseNote? forInstalled(InstalledVersion installed) {
    final build = installed.build;
    if (build == null) return null;
    for (final r in releases) {
      if (r.build == build && r.version == installed.version) return r;
    }
    return null;
  }

  /// Releases before [installed], newest first.
  List<ReleaseNote> olderThan(InstalledVersion installed) {
    final build = installed.build;
    if (build == null) return const [];
    return [
      for (final r in releases)
        if (r.build < build) r,
    ];
  }
}
