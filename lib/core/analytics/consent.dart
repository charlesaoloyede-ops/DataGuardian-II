import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../di/injection.dart';
import 'i_analytics_service.dart';

/// Applies the user's anonymous-data opt-in to every reporting SDK at once, so
/// they can never drift apart. Both analytics and Crashlytics collection follow
/// [enabled]. Default is off — the manifest `*_collection_enabled=false`
/// meta-data means nothing is collected until this runs with `true`.
Future<void> applyDataConsent(bool enabled) async {
  await getIt<IAnalyticsService>().setEnabled(enabled);
  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  } catch (_) {
    // Firebase not initialised in this build variant — nothing to toggle.
  }
}

/// Internal diagnostics only (surfaced behind `BuildConfig.internalTools`).
/// Forces Crashlytics collection on for this session and sends a non-fatal test
/// report, then flushes it, so we can confirm reports reach the Firebase console
/// without waiting for — or forcing — a real crash. Never wired into public UI.
Future<void> sendTestCrashReport() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(true);
  await crashlytics.recordError(
    Exception('Data Guardian test crash — internal diagnostics'),
    StackTrace.current,
    reason: 'INTERNAL_TOOLS verification',
    fatal: false,
  );
  await crashlytics.sendUnsentReports();
}
