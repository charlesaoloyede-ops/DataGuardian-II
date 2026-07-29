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

  /// Whether the OS will actually deliver notifications (permission granted and
  /// notifications not disabled). When false, alerts are still recorded in the
  /// Alerts Center but no system notification appears.
  Future<bool> areNotificationsEnabled();

  /// Opens the system notification settings for the app.
  Future<void> openNotificationSettings();

  /// Posts a real system notification immediately so the user can confirm
  /// tray delivery works.
  Future<void> sendTestNotification();

  /// Posts a budget conversion-nudge notification immediately (internal builds)
  /// so the notification + its deep-link to App Usage can be verified without
  /// waiting for the 3-day cadence.
  Future<void> sendTestNudge();

  /// Posts a limits conversion-nudge notification immediately (internal builds)
  /// so the notification + its deep-link to the data-limit settings can be
  /// verified without waiting for the 3-day cadence.
  Future<void> sendTestLimitsNudge();
}
