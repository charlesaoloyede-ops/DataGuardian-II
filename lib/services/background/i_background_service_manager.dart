abstract class IBackgroundServiceManager {
  /// Schedules the native periodic usage monitor (WorkManager).
  Future<void> startService();

  /// Cancels the native periodic usage monitor.
  Future<void> stopService();

  /// Whether the app is exempt from battery optimization — the main factor in
  /// whether the monitor keeps running on aggressive OEMs.
  Future<bool> isIgnoringBatteryOptimizations();

  /// Prompts the user (system dialog) to exempt the app from battery
  /// optimization.
  Future<void> requestIgnoreBatteryOptimizations();
}
