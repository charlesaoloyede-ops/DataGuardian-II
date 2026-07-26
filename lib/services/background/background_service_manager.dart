import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'i_background_service_manager.dart';

/// Controls the native background usage monitor.
///
/// Evaluation runs in native Kotlin via WorkManager (see [UsageMonitorWorker]),
/// not a Dart isolate — the isolate has no access to the app's platform
/// channels and is easily killed by OEM battery management. This class is a
/// thin bridge that schedules / cancels that work and manages the
/// battery-optimization exemption.
@LazySingleton(as: IBackgroundServiceManager)
class BackgroundServiceManager implements IBackgroundServiceManager {
  static const _channel = MethodChannel('com.dataguardian/monitor');

  @override
  Future<void> startService() async {
    await _channel.invokeMethod<bool>('startMonitoring');
  }

  @override
  Future<void> stopService() async {
    await _channel.invokeMethod<bool>('stopMonitoring');
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
  }

  @override
  Future<bool> areNotificationsEnabled() async =>
      await _channel.invokeMethod<bool>('areNotificationsEnabled') ?? true;

  @override
  Future<void> openNotificationSettings() async {
    await _channel.invokeMethod<void>('openNotificationSettings');
  }

  @override
  Future<void> sendTestNotification() async {
    await _channel.invokeMethod<bool>('sendTestNotification');
  }

  @override
  Future<void> sendTestNudge() async {
    await _channel.invokeMethod<bool>('sendTestNudge');
  }
}
