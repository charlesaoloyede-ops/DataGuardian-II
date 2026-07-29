import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import 'i_analytics_service.dart';

/// Firebase Analytics implementation.
///
/// Collection is gated entirely by [setEnabled] → `setAnalyticsCollectionEnabled`,
/// which the app drives from the user's opt-in (`shareAnonymousAnalytics`,
/// default off). When collection is disabled, Firebase drops every event —
/// including automatic ones — so no per-call gate is needed.
///
/// Kept dependency-free on purpose: depending on the async `SharedPrefsService`
/// would make this an async get_it singleton and break the many synchronous
/// `getIt<IAnalyticsService>()` call sites.
@LazySingleton(as: IAnalyticsService)
class FirebaseAnalyticsService implements IAnalyticsService {
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  @override
  Future<void> setEnabled(bool enabled) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) async {
    await _analytics.logEvent(
      name: name,
      parameters: properties == null
          ? null
          : {
              for (final e in properties.entries)
                if (e.value != null) e.key: e.value as Object,
            },
    );
  }
}
