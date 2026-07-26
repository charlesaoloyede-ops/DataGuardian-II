/// Release metadata published to Firestore `app_config/latest_release` and used
/// by the in-app updater for sideloaded (non-Play) distribution.
class AppRelease {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final String changelog;
  final bool mandatory;

  /// Installs older than this must update before continuing.
  final int minSupportedVersionCode;

  const AppRelease({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.changelog,
    required this.mandatory,
    required this.minSupportedVersionCode,
  });

  factory AppRelease.fromMap(Map<String, dynamic> m) => AppRelease(
        versionCode: (m['versionCode'] as num?)?.toInt() ?? 0,
        versionName: (m['versionName'] as String?) ?? '',
        apkUrl: (m['apkUrl'] as String?) ?? '',
        changelog: (m['changelog'] as String?) ?? '',
        mandatory: (m['mandatory'] as bool?) ?? false,
        minSupportedVersionCode:
            (m['minSupportedVersionCode'] as num?)?.toInt() ?? 0,
      );
}

/// Result of a version check: the available release and whether updating is
/// mandatory (publisher-forced, or the install is below the minimum supported).
class AppUpdateInfo {
  final AppRelease release;
  final bool mandatory;
  const AppUpdateInfo({required this.release, required this.mandatory});
}
