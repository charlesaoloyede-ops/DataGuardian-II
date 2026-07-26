abstract class AppConstants {
  // App identity
  // Keep in sync with pubspec `version:` until package_info_plus is added.
  static const String appVersion = '1.3.0+4';

  // Hive box names
  static const String appUsageBox = 'app_usage_records';
  static const String dailyUsageBox = 'daily_usage_summaries';
  static const String alertsBox = 'alert_records';

  // SharedPreferences keys
  static const String keyOnboardingComplete = 'onboarding_completed';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBillingCycleStartDay = 'billing_cycle_start_day';
  static const String keySpikeMultiplier = 'spike_threshold_multiplier';
  static const String keyDailyThresholdBytes = 'daily_threshold_bytes';
  static const String keyWeeklyThresholdBytes = 'weekly_threshold_bytes';
  static const String keyBackgroundThresholdBytes = 'background_threshold_bytes';
  static const String keyDarkMode = 'dark_mode_preference';

  // Platform channel names
  static const String networkStatsChannel = 'com.dataguardian/network_stats';
  static const String usageStatsChannel = 'com.dataguardian/usage_stats';

  // Notification channels
  static const String alertChannelId = 'data_guardian_alerts';
  static const String alertChannelName = 'Data Alerts';
  static const String monitorChannelId = 'data_guardian_monitor';
  static const String monitorChannelName = 'Background Monitor';

  // Business rules
  static const int maxDateRangeMonths = 4;
  static const int alertHistoryLimit = 100;
  static const int dashboardTopAppsCount = 5;
  static const double defaultSpikeMultiplier = 1.5;
  static const int minBaselineDays = 3;
  static const int baselineLookbackDays = 7;
  static const int backgroundPollIntervalMinutes = 15;
  static const int lowBatteryPollIntervalMinutes = 30;
  static const int lowBatteryThresholdPercent = 20;

  // Impact thresholds (bytes per day for background usage)
  static const int highImpactBytes = 100 * 1000 * 1000; // 100 MB
  static const int mediumImpactBytes = 10 * 1000 * 1000; // 10 MB
}
