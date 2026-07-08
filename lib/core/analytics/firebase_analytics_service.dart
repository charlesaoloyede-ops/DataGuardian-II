import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';
import '../../services/storage/shared_prefs_service.dart';
import 'i_analytics_service.dart';

/// Firebase Analytics implementation, gated by the user's opt-in
/// (`shareAnonymousAnalytics`, default off). No sign-in and no PII — Firebase
/// assigns an anonymous app-instance id. See docs/backend/firestore-schema.md §5.
@LazySingleton(as: IAnalyticsService)
class FirebaseAnalyticsService implements IAnalyticsService {
  final SharedPrefsService _prefs;
  FirebaseAnalyticsService(this._prefs);

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  bool get _optedIn => _prefs.getPreferences().shareAnonymousAnalytics;

  @override
  Future<void> setEnabled(bool enabled) async {
    // Governs automatic collection too (screen views, sessions, first_open).
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) async {
    if (!_optedIn) return;
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
