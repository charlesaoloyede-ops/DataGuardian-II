import 'package:flutter/foundation.dart';
import 'i_analytics_service.dart';

/// No-op analytics used in tests and as a Firebase-free fallback. Not
/// registered in DI — [FirebaseAnalyticsService] is the bound implementation.
class NoOpAnalyticsService implements IAnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) async {
    debugPrint('[Analytics] $name ${properties ?? {}}');
  }

  @override
  Future<void> setEnabled(bool enabled) async {}
}
