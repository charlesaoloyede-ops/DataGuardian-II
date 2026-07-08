import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    int? dailyThresholdBytes,
    int? weeklyThresholdBytes,
    @Default(1.5) double spikeThresholdMultiplier,
    int? backgroundThresholdBytes,
    /// 1–28 or -1 if not set (use last 30 days instead).
    @Default(-1) int billingCycleStartDay,
    @Default(true) bool notificationsEnabled,
    @Default(false) bool isDarkMode,

    /// Opt-in (default off) to share anonymous usage analytics. Gates all
    /// Firebase Analytics collection. See docs/backend/firestore-schema.md §5.
    @Default(false) bool shareAnonymousAnalytics,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}
