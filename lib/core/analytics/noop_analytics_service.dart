import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'i_analytics_service.dart';

@LazySingleton(as: IAnalyticsService)
class NoOpAnalyticsService implements IAnalyticsService {
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? properties}) async {
    debugPrint('[Analytics] $name ${properties ?? {}}');
  }
}
