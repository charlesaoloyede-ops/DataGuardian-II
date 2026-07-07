// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) {
  return _UserPreferences.fromJson(json);
}

/// @nodoc
mixin _$UserPreferences {
  int? get dailyThresholdBytes => throw _privateConstructorUsedError;
  int? get weeklyThresholdBytes => throw _privateConstructorUsedError;
  double get spikeThresholdMultiplier => throw _privateConstructorUsedError;
  int? get backgroundThresholdBytes => throw _privateConstructorUsedError;

  /// 1–28 or -1 if not set (use last 30 days instead).
  int get billingCycleStartDay => throw _privateConstructorUsedError;
  bool get notificationsEnabled => throw _privateConstructorUsedError;
  bool get isDarkMode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserPreferencesCopyWith<UserPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPreferencesCopyWith<$Res> {
  factory $UserPreferencesCopyWith(
          UserPreferences value, $Res Function(UserPreferences) then) =
      _$UserPreferencesCopyWithImpl<$Res, UserPreferences>;
  @useResult
  $Res call(
      {int? dailyThresholdBytes,
      int? weeklyThresholdBytes,
      double spikeThresholdMultiplier,
      int? backgroundThresholdBytes,
      int billingCycleStartDay,
      bool notificationsEnabled,
      bool isDarkMode});
}

/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res, $Val extends UserPreferences>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyThresholdBytes = freezed,
    Object? weeklyThresholdBytes = freezed,
    Object? spikeThresholdMultiplier = null,
    Object? backgroundThresholdBytes = freezed,
    Object? billingCycleStartDay = null,
    Object? notificationsEnabled = null,
    Object? isDarkMode = null,
  }) {
    return _then(_value.copyWith(
      dailyThresholdBytes: freezed == dailyThresholdBytes
          ? _value.dailyThresholdBytes
          : dailyThresholdBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      weeklyThresholdBytes: freezed == weeklyThresholdBytes
          ? _value.weeklyThresholdBytes
          : weeklyThresholdBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      spikeThresholdMultiplier: null == spikeThresholdMultiplier
          ? _value.spikeThresholdMultiplier
          : spikeThresholdMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      backgroundThresholdBytes: freezed == backgroundThresholdBytes
          ? _value.backgroundThresholdBytes
          : backgroundThresholdBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      billingCycleStartDay: null == billingCycleStartDay
          ? _value.billingCycleStartDay
          : billingCycleStartDay // ignore: cast_nullable_to_non_nullable
              as int,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isDarkMode: null == isDarkMode
          ? _value.isDarkMode
          : isDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserPreferencesImplCopyWith<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  factory _$$UserPreferencesImplCopyWith(_$UserPreferencesImpl value,
          $Res Function(_$UserPreferencesImpl) then) =
      __$$UserPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? dailyThresholdBytes,
      int? weeklyThresholdBytes,
      double spikeThresholdMultiplier,
      int? backgroundThresholdBytes,
      int billingCycleStartDay,
      bool notificationsEnabled,
      bool isDarkMode});
}

/// @nodoc
class __$$UserPreferencesImplCopyWithImpl<$Res>
    extends _$UserPreferencesCopyWithImpl<$Res, _$UserPreferencesImpl>
    implements _$$UserPreferencesImplCopyWith<$Res> {
  __$$UserPreferencesImplCopyWithImpl(
      _$UserPreferencesImpl _value, $Res Function(_$UserPreferencesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyThresholdBytes = freezed,
    Object? weeklyThresholdBytes = freezed,
    Object? spikeThresholdMultiplier = null,
    Object? backgroundThresholdBytes = freezed,
    Object? billingCycleStartDay = null,
    Object? notificationsEnabled = null,
    Object? isDarkMode = null,
  }) {
    return _then(_$UserPreferencesImpl(
      dailyThresholdBytes: freezed == dailyThresholdBytes
          ? _value.dailyThresholdBytes
          : dailyThresholdBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      weeklyThresholdBytes: freezed == weeklyThresholdBytes
          ? _value.weeklyThresholdBytes
          : weeklyThresholdBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      spikeThresholdMultiplier: null == spikeThresholdMultiplier
          ? _value.spikeThresholdMultiplier
          : spikeThresholdMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      backgroundThresholdBytes: freezed == backgroundThresholdBytes
          ? _value.backgroundThresholdBytes
          : backgroundThresholdBytes // ignore: cast_nullable_to_non_nullable
              as int?,
      billingCycleStartDay: null == billingCycleStartDay
          ? _value.billingCycleStartDay
          : billingCycleStartDay // ignore: cast_nullable_to_non_nullable
              as int,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isDarkMode: null == isDarkMode
          ? _value.isDarkMode
          : isDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPreferencesImpl implements _UserPreferences {
  const _$UserPreferencesImpl(
      {this.dailyThresholdBytes,
      this.weeklyThresholdBytes,
      this.spikeThresholdMultiplier = 1.5,
      this.backgroundThresholdBytes,
      this.billingCycleStartDay = -1,
      this.notificationsEnabled = true,
      this.isDarkMode = false});

  factory _$UserPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPreferencesImplFromJson(json);

  @override
  final int? dailyThresholdBytes;
  @override
  final int? weeklyThresholdBytes;
  @override
  @JsonKey()
  final double spikeThresholdMultiplier;
  @override
  final int? backgroundThresholdBytes;

  /// 1–28 or -1 if not set (use last 30 days instead).
  @override
  @JsonKey()
  final int billingCycleStartDay;
  @override
  @JsonKey()
  final bool notificationsEnabled;
  @override
  @JsonKey()
  final bool isDarkMode;

  @override
  String toString() {
    return 'UserPreferences(dailyThresholdBytes: $dailyThresholdBytes, weeklyThresholdBytes: $weeklyThresholdBytes, spikeThresholdMultiplier: $spikeThresholdMultiplier, backgroundThresholdBytes: $backgroundThresholdBytes, billingCycleStartDay: $billingCycleStartDay, notificationsEnabled: $notificationsEnabled, isDarkMode: $isDarkMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPreferencesImpl &&
            (identical(other.dailyThresholdBytes, dailyThresholdBytes) ||
                other.dailyThresholdBytes == dailyThresholdBytes) &&
            (identical(other.weeklyThresholdBytes, weeklyThresholdBytes) ||
                other.weeklyThresholdBytes == weeklyThresholdBytes) &&
            (identical(
                    other.spikeThresholdMultiplier, spikeThresholdMultiplier) ||
                other.spikeThresholdMultiplier == spikeThresholdMultiplier) &&
            (identical(
                    other.backgroundThresholdBytes, backgroundThresholdBytes) ||
                other.backgroundThresholdBytes == backgroundThresholdBytes) &&
            (identical(other.billingCycleStartDay, billingCycleStartDay) ||
                other.billingCycleStartDay == billingCycleStartDay) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dailyThresholdBytes,
      weeklyThresholdBytes,
      spikeThresholdMultiplier,
      backgroundThresholdBytes,
      billingCycleStartDay,
      notificationsEnabled,
      isDarkMode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      __$$UserPreferencesImplCopyWithImpl<_$UserPreferencesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPreferencesImplToJson(
      this,
    );
  }
}

abstract class _UserPreferences implements UserPreferences {
  const factory _UserPreferences(
      {final int? dailyThresholdBytes,
      final int? weeklyThresholdBytes,
      final double spikeThresholdMultiplier,
      final int? backgroundThresholdBytes,
      final int billingCycleStartDay,
      final bool notificationsEnabled,
      final bool isDarkMode}) = _$UserPreferencesImpl;

  factory _UserPreferences.fromJson(Map<String, dynamic> json) =
      _$UserPreferencesImpl.fromJson;

  @override
  int? get dailyThresholdBytes;
  @override
  int? get weeklyThresholdBytes;
  @override
  double get spikeThresholdMultiplier;
  @override
  int? get backgroundThresholdBytes;
  @override

  /// 1–28 or -1 if not set (use last 30 days instead).
  int get billingCycleStartDay;
  @override
  bool get notificationsEnabled;
  @override
  bool get isDarkMode;
  @override
  @JsonKey(ignore: true)
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
