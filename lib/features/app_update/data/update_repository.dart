import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../domain/app_release.dart';
import '../domain/i_update_repository.dart';
import 'app_installer.dart';

/// Reads the published release from Firestore, compares it to the installed
/// version, and downloads/installs the APK for sideloaded distribution.
///
/// Dependency-free so it stays a synchronous get_it singleton.
@LazySingleton(as: IUpdateRepository)
class UpdateRepository implements IUpdateRepository {
  final AppInstaller _installer = AppInstaller();
  final Dio _dio = Dio();

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('app_config')
      .doc('latest_release');

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    final snap = await _doc.get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;

    final release = AppRelease.fromMap(data);
    if (release.apkUrl.isEmpty) return null;

    final installed = await _installer.installedVersionCode();
    if (release.versionCode <= installed) return null;

    final mandatory =
        release.mandatory || installed < release.minSupportedVersionCode;
    return AppUpdateInfo(release: release, mandatory: mandatory);
  }

  @override
  Future<String> downloadApk(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _installer.downloadDir();
    if (dir == null) {
      throw Exception('No writable storage available for the update.');
    }
    final path = '$dir/update-${release.versionCode}.apk';
    await _dio.download(
      release.apkUrl,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) onProgress(received / total);
      },
    );
    return path;
  }

  @override
  Future<bool> canInstall() => _installer.canInstall();

  @override
  Future<void> openInstallSettings() => _installer.openInstallSettings();

  @override
  Future<void> install(String apkPath) => _installer.install(apkPath);
}
