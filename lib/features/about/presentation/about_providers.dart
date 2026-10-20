import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_info_source.dart';
import '../domain/release_notes.dart';

/// Version metadata of the installed app. Tests override this.
final appInfoSourceProvider = Provider<AppInfoSource>(
  (ref) => const PackageInfoAppInfoSource(),
);

/// Loads the bundled release notes file. Tests may override this.
/// [releaseNotesProvider] keeps the result, so the bundle's own cache is
/// not used.
final releaseNotesLoaderProvider = Provider<Future<String> Function()>(
  (ref) =>
      () => rootBundle.loadString(ReleaseNotes.assetPath, cache: false),
);

/// The version and build number of the app as installed on this device.
final installedVersionProvider = FutureProvider<InstalledVersion>(
  (ref) => ref.watch(appInfoSourceProvider).installedVersion(),
);

final releaseNotesProvider = FutureProvider<ReleaseNotes>(
  (ref) async =>
      ReleaseNotes.parse(await ref.watch(releaseNotesLoaderProvider)()),
);
