// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_usage_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppUsageRecord {
  @HiveField(0)
  String get packageName => throw _privateConstructorUsedError;
  @HiveField(1)
  String get appName => throw _privateConstructorUsedError;

  /// Mobile data used in foreground (bytes).
  @HiveField(2)
  int get mobileForegroundBytes => throw _privateConstructorUsedError;

  /// Mobile data used in background (bytes).
  @HiveField(3)
  int get mobileBackgroundBytes => throw _privateConstructorUsedError;

  /// Wi-Fi data used in foreground (bytes).
  @HiveField(4)
  int get wifiForegroundBytes => throw _privateConstructorUsedError;

  /// Wi-Fi data used in background (bytes).
  @HiveField(5)
  int get wifiBackgroundBytes => throw _privateConstructorUsedError;

  /// Screen-on time from UsageStatsManager (ms).
  @HiveField(6)
  int get foregroundTimeMs => throw _privateConstructorUsedError;
  @HiveField(7)
  DateTime get periodStart => throw _privateConstructorUsedError;
  @HiveField(8)
  DateTime get periodEnd => throw _privateConstructorUsedError;
  @HiveField(9)
  String? get appIconBase64 => throw _privateConstructorUsedError;
  @HiveField(10)
  bool get isSystemApp => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppUsageRecordCopyWith<AppUsageRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUsageRecordCopyWith<$Res> {
  factory $AppUsageRecordCopyWith(
          AppUsageRecord value, $Res Function(AppUsageRecord) then) =
      _$AppUsageRecordCopyWithImpl<$Res, AppUsageRecord>;
  @useResult
  $Res call(
      {@HiveField(0) String packageName,
      @HiveField(1) String appName,
      @HiveField(2) int mobileForegroundBytes,
      @HiveField(3) int mobileBackgroundBytes,
      @HiveField(4) int wifiForegroundBytes,
      @HiveField(5) int wifiBackgroundBytes,
      @HiveField(6) int foregroundTimeMs,
      @HiveField(7) DateTime periodStart,
      @HiveField(8) DateTime periodEnd,
      @HiveField(9) String? appIconBase64,
      @HiveField(10) bool isSystemApp});
}

/// @nodoc
class _$AppUsageRecordCopyWithImpl<$Res, $Val extends AppUsageRecord>
    implements $AppUsageRecordCopyWith<$Res> {
  _$AppUsageRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packageName = null,
    Object? appName = null,
    Object? mobileForegroundBytes = null,
    Object? mobileBackgroundBytes = null,
    Object? wifiForegroundBytes = null,
    Object? wifiBackgroundBytes = null,
    Object? foregroundTimeMs = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? appIconBase64 = freezed,
    Object? isSystemApp = null,
  }) {
    return _then(_value.copyWith(
      packageName: null == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      appName: null == appName
          ? _value.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
      mobileForegroundBytes: null == mobileForegroundBytes
          ? _value.mobileForegroundBytes
          : mobileForegroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mobileBackgroundBytes: null == mobileBackgroundBytes
          ? _value.mobileBackgroundBytes
          : mobileBackgroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      wifiForegroundBytes: null == wifiForegroundBytes
          ? _value.wifiForegroundBytes
          : wifiForegroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      wifiBackgroundBytes: null == wifiBackgroundBytes
          ? _value.wifiBackgroundBytes
          : wifiBackgroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      foregroundTimeMs: null == foregroundTimeMs
          ? _value.foregroundTimeMs
          : foregroundTimeMs // ignore: cast_nullable_to_non_nullable
              as int,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      appIconBase64: freezed == appIconBase64
          ? _value.appIconBase64
          : appIconBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      isSystemApp: null == isSystemApp
          ? _value.isSystemApp
          : isSystemApp // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppUsageRecordImplCopyWith<$Res>
    implements $AppUsageRecordCopyWith<$Res> {
  factory _$$AppUsageRecordImplCopyWith(_$AppUsageRecordImpl value,
          $Res Function(_$AppUsageRecordImpl) then) =
      __$$AppUsageRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String packageName,
      @HiveField(1) String appName,
      @HiveField(2) int mobileForegroundBytes,
      @HiveField(3) int mobileBackgroundBytes,
      @HiveField(4) int wifiForegroundBytes,
      @HiveField(5) int wifiBackgroundBytes,
      @HiveField(6) int foregroundTimeMs,
      @HiveField(7) DateTime periodStart,
      @HiveField(8) DateTime periodEnd,
      @HiveField(9) String? appIconBase64,
      @HiveField(10) bool isSystemApp});
}

/// @nodoc
class __$$AppUsageRecordImplCopyWithImpl<$Res>
    extends _$AppUsageRecordCopyWithImpl<$Res, _$AppUsageRecordImpl>
    implements _$$AppUsageRecordImplCopyWith<$Res> {
  __$$AppUsageRecordImplCopyWithImpl(
      _$AppUsageRecordImpl _value, $Res Function(_$AppUsageRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? packageName = null,
    Object? appName = null,
    Object? mobileForegroundBytes = null,
    Object? mobileBackgroundBytes = null,
    Object? wifiForegroundBytes = null,
    Object? wifiBackgroundBytes = null,
    Object? foregroundTimeMs = null,
    Object? periodStart = null,
    Object? periodEnd = null,
    Object? appIconBase64 = freezed,
    Object? isSystemApp = null,
  }) {
    return _then(_$AppUsageRecordImpl(
      packageName: null == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String,
      appName: null == appName
          ? _value.appName
          : appName // ignore: cast_nullable_to_non_nullable
              as String,
      mobileForegroundBytes: null == mobileForegroundBytes
          ? _value.mobileForegroundBytes
          : mobileForegroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mobileBackgroundBytes: null == mobileBackgroundBytes
          ? _value.mobileBackgroundBytes
          : mobileBackgroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      wifiForegroundBytes: null == wifiForegroundBytes
          ? _value.wifiForegroundBytes
          : wifiForegroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      wifiBackgroundBytes: null == wifiBackgroundBytes
          ? _value.wifiBackgroundBytes
          : wifiBackgroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      foregroundTimeMs: null == foregroundTimeMs
          ? _value.foregroundTimeMs
          : foregroundTimeMs // ignore: cast_nullable_to_non_nullable
              as int,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
      appIconBase64: freezed == appIconBase64
          ? _value.appIconBase64
          : appIconBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      isSystemApp: null == isSystemApp
          ? _value.isSystemApp
          : isSystemApp // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AppUsageRecordImpl extends _AppUsageRecord {
  const _$AppUsageRecordImpl(
      {@HiveField(0) required this.packageName,
      @HiveField(1) required this.appName,
      @HiveField(2) required this.mobileForegroundBytes,
      @HiveField(3) required this.mobileBackgroundBytes,
      @HiveField(4) required this.wifiForegroundBytes,
      @HiveField(5) required this.wifiBackgroundBytes,
      @HiveField(6) required this.foregroundTimeMs,
      @HiveField(7) required this.periodStart,
      @HiveField(8) required this.periodEnd,
      @HiveField(9) this.appIconBase64,
      @HiveField(10) this.isSystemApp = false})
      : super._();

  @override
  @HiveField(0)
  final String packageName;
  @override
  @HiveField(1)
  final String appName;

  /// Mobile data used in foreground (bytes).
  @override
  @HiveField(2)
  final int mobileForegroundBytes;

  /// Mobile data used in background (bytes).
  @override
  @HiveField(3)
  final int mobileBackgroundBytes;

  /// Wi-Fi data used in foreground (bytes).
  @override
  @HiveField(4)
  final int wifiForegroundBytes;

  /// Wi-Fi data used in background (bytes).
  @override
  @HiveField(5)
  final int wifiBackgroundBytes;

  /// Screen-on time from UsageStatsManager (ms).
  @override
  @HiveField(6)
  final int foregroundTimeMs;
  @override
  @HiveField(7)
  final DateTime periodStart;
  @override
  @HiveField(8)
  final DateTime periodEnd;
  @override
  @HiveField(9)
  final String? appIconBase64;
  @override
  @JsonKey()
  @HiveField(10)
  final bool isSystemApp;

  @override
  String toString() {
    return 'AppUsageRecord(packageName: $packageName, appName: $appName, mobileForegroundBytes: $mobileForegroundBytes, mobileBackgroundBytes: $mobileBackgroundBytes, wifiForegroundBytes: $wifiForegroundBytes, wifiBackgroundBytes: $wifiBackgroundBytes, foregroundTimeMs: $foregroundTimeMs, periodStart: $periodStart, periodEnd: $periodEnd, appIconBase64: $appIconBase64, isSystemApp: $isSystemApp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUsageRecordImpl &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.appName, appName) || other.appName == appName) &&
            (identical(other.mobileForegroundBytes, mobileForegroundBytes) ||
                other.mobileForegroundBytes == mobileForegroundBytes) &&
            (identical(other.mobileBackgroundBytes, mobileBackgroundBytes) ||
                other.mobileBackgroundBytes == mobileBackgroundBytes) &&
            (identical(other.wifiForegroundBytes, wifiForegroundBytes) ||
                other.wifiForegroundBytes == wifiForegroundBytes) &&
            (identical(other.wifiBackgroundBytes, wifiBackgroundBytes) ||
                other.wifiBackgroundBytes == wifiBackgroundBytes) &&
            (identical(other.foregroundTimeMs, foregroundTimeMs) ||
                other.foregroundTimeMs == foregroundTimeMs) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd) &&
            (identical(other.appIconBase64, appIconBase64) ||
                other.appIconBase64 == appIconBase64) &&
            (identical(other.isSystemApp, isSystemApp) ||
                other.isSystemApp == isSystemApp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      packageName,
      appName,
      mobileForegroundBytes,
      mobileBackgroundBytes,
      wifiForegroundBytes,
      wifiBackgroundBytes,
      foregroundTimeMs,
      periodStart,
      periodEnd,
      appIconBase64,
      isSystemApp);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUsageRecordImplCopyWith<_$AppUsageRecordImpl> get copyWith =>
      __$$AppUsageRecordImplCopyWithImpl<_$AppUsageRecordImpl>(
          this, _$identity);
}

abstract class _AppUsageRecord extends AppUsageRecord {
  const factory _AppUsageRecord(
      {@HiveField(0) required final String packageName,
      @HiveField(1) required final String appName,
      @HiveField(2) required final int mobileForegroundBytes,
      @HiveField(3) required final int mobileBackgroundBytes,
      @HiveField(4) required final int wifiForegroundBytes,
      @HiveField(5) required final int wifiBackgroundBytes,
      @HiveField(6) required final int foregroundTimeMs,
      @HiveField(7) required final DateTime periodStart,
      @HiveField(8) required final DateTime periodEnd,
      @HiveField(9) final String? appIconBase64,
      @HiveField(10) final bool isSystemApp}) = _$AppUsageRecordImpl;
  const _AppUsageRecord._() : super._();

  @override
  @HiveField(0)
  String get packageName;
  @override
  @HiveField(1)
  String get appName;
  @override

  /// Mobile data used in foreground (bytes).
  @HiveField(2)
  int get mobileForegroundBytes;
  @override

  /// Mobile data used in background (bytes).
  @HiveField(3)
  int get mobileBackgroundBytes;
  @override

  /// Wi-Fi data used in foreground (bytes).
  @HiveField(4)
  int get wifiForegroundBytes;
  @override

  /// Wi-Fi data used in background (bytes).
  @HiveField(5)
  int get wifiBackgroundBytes;
  @override

  /// Screen-on time from UsageStatsManager (ms).
  @HiveField(6)
  int get foregroundTimeMs;
  @override
  @HiveField(7)
  DateTime get periodStart;
  @override
  @HiveField(8)
  DateTime get periodEnd;
  @override
  @HiveField(9)
  String? get appIconBase64;
  @override
  @HiveField(10)
  bool get isSystemApp;
  @override
  @JsonKey(ignore: true)
  _$$AppUsageRecordImplCopyWith<_$AppUsageRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
