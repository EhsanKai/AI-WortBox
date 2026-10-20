import 'package:package_info_plus/package_info_plus.dart';

import '../domain/release_notes.dart';

/// Reads the installed app's version metadata. Tests use a fake.
abstract interface class AppInfoSource {
  Future<InstalledVersion> installedVersion();
}

/// The version and build number the platform reports for the running app
/// (from the app bundle / package, not from source code).
class PackageInfoAppInfoSource implements AppInfoSource {
  const PackageInfoAppInfoSource();

  @override
  Future<InstalledVersion> installedVersion() async {
    final info = await PackageInfo.fromPlatform();
    return InstalledVersion(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }
}
