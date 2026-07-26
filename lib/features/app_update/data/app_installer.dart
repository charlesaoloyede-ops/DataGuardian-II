import 'package:flutter/services.dart';

/// Thin wrapper over the native `com.dataguardian/app_update` channel
/// (see AppUpdateChannel.kt).
class AppInstaller {
  static const _channel = MethodChannel('com.dataguardian/app_update');

  Future<int> installedVersionCode() async =>
      (await _channel.invokeMethod<int>('getInstalledVersionCode')) ?? 0;

  Future<String?> downloadDir() async =>
      _channel.invokeMethod<String>('getDownloadDir');

  Future<bool> canInstall() async =>
      (await _channel.invokeMethod<bool>('canInstall')) ?? false;

  Future<void> openInstallSettings() =>
      _channel.invokeMethod('openInstallSettings');

  Future<void> install(String path) =>
      _channel.invokeMethod('install', {'path': path});
}
