// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_usage_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DailyUsageSummary {
  @HiveField(0)
  DateTime get date => throw _privateConstructorUsedError;
  @HiveField(1)
  int get totalMobileBytes => throw _privateConstructorUsedError;
  @HiveField(2)
  int get mobileForegroundBytes => throw _privateConstructorUsedError;
  @HiveField(3)
  int get mobileBackgroundBytes => throw _privateConstructorUsedError;
  @HiveField(4)
  int get totalWifiBytes => throw _privateConstructorUsedError;
  @HiveField(5)
  bool get isAnomaly => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DailyUsageSummaryCopyWith<DailyUsageSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyUsageSummaryCopyWith<$Res> {
  factory $DailyUsageSummaryCopyWith(
          DailyUsageSummary value, $Res Function(DailyUsageSummary) then) =
      _$DailyUsageSummaryCopyWithImpl<$Res, DailyUsageSummary>;
  @useResult
  $Res call(
      {@HiveField(0) DateTime date,
      @HiveField(1) int totalMobileBytes,
      @HiveField(2) int mobileForegroundBytes,
      @HiveField(3) int mobileBackgroundBytes,
      @HiveField(4) int totalWifiBytes,
      @HiveField(5) bool isAnomaly});
}

/// @nodoc
class _$DailyUsageSummaryCopyWithImpl<$Res, $Val extends DailyUsageSummary>
    implements $DailyUsageSummaryCopyWith<$Res> {
  _$DailyUsageSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? totalMobileBytes = null,
    Object? mobileForegroundBytes = null,
    Object? mobileBackgroundBytes = null,
    Object? totalWifiBytes = null,
    Object? isAnomaly = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalMobileBytes: null == totalMobileBytes
          ? _value.totalMobileBytes
          : totalMobileBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mobileForegroundBytes: null == mobileForegroundBytes
          ? _value.mobileForegroundBytes
          : mobileForegroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mobileBackgroundBytes: null == mobileBackgroundBytes
          ? _value.mobileBackgroundBytes
          : mobileBackgroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      totalWifiBytes: null == totalWifiBytes
          ? _value.totalWifiBytes
          : totalWifiBytes // ignore: cast_nullable_to_non_nullable
              as int,
      isAnomaly: null == isAnomaly
          ? _value.isAnomaly
          : isAnomaly // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyUsageSummaryImplCopyWith<$Res>
    implements $DailyUsageSummaryCopyWith<$Res> {
  factory _$$DailyUsageSummaryImplCopyWith(_$DailyUsageSummaryImpl value,
          $Res Function(_$DailyUsageSummaryImpl) then) =
      __$$DailyUsageSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) DateTime date,
      @HiveField(1) int totalMobileBytes,
      @HiveField(2) int mobileForegroundBytes,
      @HiveField(3) int mobileBackgroundBytes,
      @HiveField(4) int totalWifiBytes,
      @HiveField(5) bool isAnomaly});
}

/// @nodoc
class __$$DailyUsageSummaryImplCopyWithImpl<$Res>
    extends _$DailyUsageSummaryCopyWithImpl<$Res, _$DailyUsageSummaryImpl>
    implements _$$DailyUsageSummaryImplCopyWith<$Res> {
  __$$DailyUsageSummaryImplCopyWithImpl(_$DailyUsageSummaryImpl _value,
      $Res Function(_$DailyUsageSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? totalMobileBytes = null,
    Object? mobileForegroundBytes = null,
    Object? mobileBackgroundBytes = null,
    Object? totalWifiBytes = null,
    Object? isAnomaly = null,
  }) {
    return _then(_$DailyUsageSummaryImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalMobileBytes: null == totalMobileBytes
          ? _value.totalMobileBytes
          : totalMobileBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mobileForegroundBytes: null == mobileForegroundBytes
          ? _value.mobileForegroundBytes
          : mobileForegroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      mobileBackgroundBytes: null == mobileBackgroundBytes
          ? _value.mobileBackgroundBytes
          : mobileBackgroundBytes // ignore: cast_nullable_to_non_nullable
              as int,
      totalWifiBytes: null == totalWifiBytes
          ? _value.totalWifiBytes
          : totalWifiBytes // ignore: cast_nullable_to_non_nullable
              as int,
      isAnomaly: null == isAnomaly
          ? _value.isAnomaly
          : isAnomaly // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DailyUsageSummaryImpl implements _DailyUsageSummary {
  const _$DailyUsageSummaryImpl(
      {@HiveField(0) required this.date,
      @HiveField(1) required this.totalMobileBytes,
      @HiveField(2) required this.mobileForegroundBytes,
      @HiveField(3) required this.mobileBackgroundBytes,
      @HiveField(4) required this.totalWifiBytes,
      @HiveField(5) this.isAnomaly = false});

  @override
  @HiveField(0)
  final DateTime date;
  @override
  @HiveField(1)
  final int totalMobileBytes;
  @override
  @HiveField(2)
  final int mobileForegroundBytes;
  @override
  @HiveField(3)
  final int mobileBackgroundBytes;
  @override
  @HiveField(4)
  final int totalWifiBytes;
  @override
  @JsonKey()
  @HiveField(5)
  final bool isAnomaly;

  @override
  String toString() {
    return 'DailyUsageSummary(date: $date, totalMobileBytes: $totalMobileBytes, mobileForegroundBytes: $mobileForegroundBytes, mobileBackgroundBytes: $mobileBackgroundBytes, totalWifiBytes: $totalWifiBytes, isAnomaly: $isAnomaly)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyUsageSummaryImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalMobileBytes, totalMobileBytes) ||
                other.totalMobileBytes == totalMobileBytes) &&
            (identical(other.mobileForegroundBytes, mobileForegroundBytes) ||
                other.mobileForegroundBytes == mobileForegroundBytes) &&
            (identical(other.mobileBackgroundBytes, mobileBackgroundBytes) ||
                other.mobileBackgroundBytes == mobileBackgroundBytes) &&
            (identical(other.totalWifiBytes, totalWifiBytes) ||
                other.totalWifiBytes == totalWifiBytes) &&
            (identical(other.isAnomaly, isAnomaly) ||
                other.isAnomaly == isAnomaly));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, totalMobileBytes,
      mobileForegroundBytes, mobileBackgroundBytes, totalWifiBytes, isAnomaly);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyUsageSummaryImplCopyWith<_$DailyUsageSummaryImpl> get copyWith =>
      __$$DailyUsageSummaryImplCopyWithImpl<_$DailyUsageSummaryImpl>(
          this, _$identity);
}

abstract class _DailyUsageSummary implements DailyUsageSummary {
  const factory _DailyUsageSummary(
      {@HiveField(0) required final DateTime date,
      @HiveField(1) required final int totalMobileBytes,
      @HiveField(2) required final int mobileForegroundBytes,
      @HiveField(3) required final int mobileBackgroundBytes,
      @HiveField(4) required final int totalWifiBytes,
      @HiveField(5) final bool isAnomaly}) = _$DailyUsageSummaryImpl;

  @override
  @HiveField(0)
  DateTime get date;
  @override
  @HiveField(1)
  int get totalMobileBytes;
  @override
  @HiveField(2)
  int get mobileForegroundBytes;
  @override
  @HiveField(3)
  int get mobileBackgroundBytes;
  @override
  @HiveField(4)
  int get totalWifiBytes;
  @override
  @HiveField(5)
  bool get isAnomaly;
  @override
  @JsonKey(ignore: true)
  _$$DailyUsageSummaryImplCopyWith<_$DailyUsageSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
