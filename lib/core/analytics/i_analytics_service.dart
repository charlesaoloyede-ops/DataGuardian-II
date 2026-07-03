abstract class IAnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? properties});
}

abstract class AnalyticsEvents {
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String permissionGranted = 'permission_granted';
  static const String permissionDenied = 'permission_denied';
  static const String permissionSkipped = 'permission_skipped';
  static const String dashboardViewed = 'dashboard_viewed';
  static const String appUsageViewed = 'app_usage_viewed';
  static const String backgroundUsageViewed = 'background_usage_viewed';
  static const String alertClicked = 'alert_clicked';
  static const String networkStatsRestricted = 'network_stats_restricted';
  static const String spikeAlertFired = 'spike_alert_fired';
  static const String thresholdAlertFired = 'threshold_alert_fired';
}
