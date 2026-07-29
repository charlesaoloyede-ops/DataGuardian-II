// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_submission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeedbackSubmission _$FeedbackSubmissionFromJson(Map<String, dynamic> json) {
  return _FeedbackSubmission.fromJson(json);
}

/// @nodoc
mixin _$FeedbackSubmission {
  String get message => throw _privateConstructorUsedError;
  FeedbackCategory get category => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String get installId => throw _privateConstructorUsedError;
  String get appVersion => throw _privateConstructorUsedError;
  String get platform => throw _privateConstructorUsedError;
  String? get osVersion => throw _privateConstructorUsedError;
  String? get deviceModel => throw _privateConstructorUsedError;
  String get createdAtIso => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeedbackSubmissionCopyWith<FeedbackSubmission> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackSubmissionCopyWith<$Res> {
  factory $FeedbackSubmissionCopyWith(
          FeedbackSubmission value, $Res Function(FeedbackSubmission) then) =
      _$FeedbackSubmissionCopyWithImpl<$Res, FeedbackSubmission>;
  @useResult
  $Res call(
      {String message,
      FeedbackCategory category,
      String? email,
      String installId,
      String appVersion,
      String platform,
      String? osVersion,
      String? deviceModel,
      String createdAtIso});
}

/// @nodoc
class _$FeedbackSubmissionCopyWithImpl<$Res, $Val extends FeedbackSubmission>
    implements $FeedbackSubmissionCopyWith<$Res> {
  _$FeedbackSubmissionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? category = null,
    Object? email = freezed,
    Object? installId = null,
    Object? appVersion = null,
    Object? platform = null,
    Object? osVersion = freezed,
    Object? deviceModel = freezed,
    Object? createdAtIso = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FeedbackCategory,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      installId: null == installId
          ? _value.installId
          : installId // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      osVersion: freezed == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAtIso: null == createdAtIso
          ? _value.createdAtIso
          : createdAtIso // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedbackSubmissionImplCopyWith<$Res>
    implements $FeedbackSubmissionCopyWith<$Res> {
  factory _$$FeedbackSubmissionImplCopyWith(_$FeedbackSubmissionImpl value,
          $Res Function(_$FeedbackSubmissionImpl) then) =
      __$$FeedbackSubmissionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      FeedbackCategory category,
      String? email,
      String installId,
      String appVersion,
      String platform,
      String? osVersion,
      String? deviceModel,
      String createdAtIso});
}

/// @nodoc
class __$$FeedbackSubmissionImplCopyWithImpl<$Res>
    extends _$FeedbackSubmissionCopyWithImpl<$Res, _$FeedbackSubmissionImpl>
    implements _$$FeedbackSubmissionImplCopyWith<$Res> {
  __$$FeedbackSubmissionImplCopyWithImpl(_$FeedbackSubmissionImpl _value,
      $Res Function(_$FeedbackSubmissionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? category = null,
    Object? email = freezed,
    Object? installId = null,
    Object? appVersion = null,
    Object? platform = null,
    Object? osVersion = freezed,
    Object? deviceModel = freezed,
    Object? createdAtIso = null,
  }) {
    return _then(_$FeedbackSubmissionImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as FeedbackCategory,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      installId: null == installId
          ? _value.installId
          : installId // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      osVersion: freezed == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAtIso: null == createdAtIso
          ? _value.createdAtIso
          : createdAtIso // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedbackSubmissionImpl implements _FeedbackSubmission {
  const _$FeedbackSubmissionImpl(
      {required this.message,
      required this.category,
      this.email,
      required this.installId,
      required this.appVersion,
      this.platform = 'android',
      this.osVersion,
      this.deviceModel,
      required this.createdAtIso});

  factory _$FeedbackSubmissionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedbackSubmissionImplFromJson(json);

  @override
  final String message;
  @override
  final FeedbackCategory category;
  @override
  final String? email;
  @override
  final String installId;
  @override
  final String appVersion;
  @override
  @JsonKey()
  final String platform;
  @override
  final String? osVersion;
  @override
  final String? deviceModel;
  @override
  final String createdAtIso;

  @override
  String toString() {
    return 'FeedbackSubmission(message: $message, category: $category, email: $email, installId: $installId, appVersion: $appVersion, platform: $platform, osVersion: $osVersion, deviceModel: $deviceModel, createdAtIso: $createdAtIso)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackSubmissionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.installId, installId) ||
                other.installId == installId) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            (identical(other.createdAtIso, createdAtIso) ||
                other.createdAtIso == createdAtIso));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, message, category, email,
      installId, appVersion, platform, osVersion, deviceModel, createdAtIso);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackSubmissionImplCopyWith<_$FeedbackSubmissionImpl> get copyWith =>
      __$$FeedbackSubmissionImplCopyWithImpl<_$FeedbackSubmissionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedbackSubmissionImplToJson(
      this,
    );
  }
}

abstract class _FeedbackSubmission implements FeedbackSubmission {
  const factory _FeedbackSubmission(
      {required final String message,
      required final FeedbackCategory category,
      final String? email,
      required final String installId,
      required final String appVersion,
      final String platform,
      final String? osVersion,
      final String? deviceModel,
      required final String createdAtIso}) = _$FeedbackSubmissionImpl;

  factory _FeedbackSubmission.fromJson(Map<String, dynamic> json) =
      _$FeedbackSubmissionImpl.fromJson;

  @override
  String get message;
  @override
  FeedbackCategory get category;
  @override
  String? get email;
  @override
  String get installId;
  @override
  String get appVersion;
  @override
  String get platform;
  @override
  String? get osVersion;
  @override
  String? get deviceModel;
  @override
  String get createdAtIso;
  @override
  @JsonKey(ignore: true)
  _$$FeedbackSubmissionImplCopyWith<_$FeedbackSubmissionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
