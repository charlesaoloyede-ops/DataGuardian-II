import 'app_release.dart';

/// Checks for and downloads app updates for sideloaded distribution.
abstract class IUpdateRepository {
  /// Returns update info if a newer release is published, else null.
  Future<AppUpdateInfo?> checkForUpdate();

  /// Downloads the release APK, reporting progress in [0,1]. Returns the local
  /// file path ready to hand to the system installer.
  Future<String> downloadApk(
    AppRelease release, {
    void Function(double progress)? onProgress,
  });

  /// Whether the OS currently permits installing APKs from this app.
  Future<bool> canInstall();

  /// Opens the system "install unknown apps" settings for this app.
  Future<void> openInstallSettings();

  /// Launches the system installer on a downloaded APK path.
  Future<void> install(String apkPath);
}
