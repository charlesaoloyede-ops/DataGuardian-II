// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPreferencesImpl _$$UserPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPreferencesImpl(
      dailyThresholdBytes: (json['dailyThresholdBytes'] as num?)?.toInt(),
      weeklyThresholdBytes: (json['weeklyThresholdBytes'] as num?)?.toInt(),
      spikeThresholdMultiplier:
          (json['spikeThresholdMultiplier'] as num?)?.toDouble() ?? 1.75,
      backgroundThresholdBytes:
          (json['backgroundThresholdBytes'] as num?)?.toInt(),
      billingCycleStartDay:
          (json['billingCycleStartDay'] as num?)?.toInt() ?? -1,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserPreferencesImplToJson(
        _$UserPreferencesImpl instance) =>
    <String, dynamic>{
      'dailyThresholdBytes': instance.dailyThresholdBytes,
      'weeklyThresholdBytes': instance.weeklyThresholdBytes,
      'spikeThresholdMultiplier': instance.spikeThresholdMultiplier,
      'backgroundThresholdBytes': instance.backgroundThresholdBytes,
      'billingCycleStartDay': instance.billingCycleStartDay,
      'notificationsEnabled': instance.notificationsEnabled,
      'isDarkMode': instance.isDarkMode,
    };
