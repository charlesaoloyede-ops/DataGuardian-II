// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alert_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AlertRecord {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  AlertType get type => throw _privateConstructorUsedError;
  @HiveField(2)
  DateTime get triggeredAt => throw _privateConstructorUsedError;
  @HiveField(3)
  String get message => throw _privateConstructorUsedError;
  @HiveField(4)
  bool get isRead => throw _privateConstructorUsedError;

  /// JSON-encoded metadata string to avoid Hive `Map<String,dynamic>` type issues.
  @HiveField(5)
  String get metadataJson => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AlertRecordCopyWith<AlertRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlertRecordCopyWith<$Res> {
  factory $AlertRecordCopyWith(
          AlertRecord value, $Res Function(AlertRecord) then) =
      _$AlertRecordCopyWithImpl<$Res, AlertRecord>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) AlertType type,
      @HiveField(2) DateTime triggeredAt,
      @HiveField(3) String message,
      @HiveField(4) bool isRead,
      @HiveField(5) String metadataJson});
}

/// @nodoc
class _$AlertRecordCopyWithImpl<$Res, $Val extends AlertRecord>
    implements $AlertRecordCopyWith<$Res> {
  _$AlertRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? triggeredAt = null,
    Object? message = null,
    Object? isRead = null,
    Object? metadataJson = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AlertType,
      triggeredAt: null == triggeredAt
          ? _value.triggeredAt
          : triggeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      metadataJson: null == metadataJson
          ? _value.metadataJson
          : metadataJson // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlertRecordImplCopyWith<$Res>
    implements $AlertRecordCopyWith<$Res> {
  factory _$$AlertRecordImplCopyWith(
          _$AlertRecordImpl value, $Res Function(_$AlertRecordImpl) then) =
      __$$AlertRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) AlertType type,
      @HiveField(2) DateTime triggeredAt,
      @HiveField(3) String message,
      @HiveField(4) bool isRead,
      @HiveField(5) String metadataJson});
}

/// @nodoc
class __$$AlertRecordImplCopyWithImpl<$Res>
    extends _$AlertRecordCopyWithImpl<$Res, _$AlertRecordImpl>
    implements _$$AlertRecordImplCopyWith<$Res> {
  __$$AlertRecordImplCopyWithImpl(
      _$AlertRecordImpl _value, $Res Function(_$AlertRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? triggeredAt = null,
    Object? message = null,
    Object? isRead = null,
    Object? metadataJson = null,
  }) {
    return _then(_$AlertRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AlertType,
      triggeredAt: null == triggeredAt
          ? _value.triggeredAt
          : triggeredAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      metadataJson: null == metadataJson
          ? _value.metadataJson
          : metadataJson // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$AlertRecordImpl implements _AlertRecord {
  const _$AlertRecordImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.type,
      @HiveField(2) required this.triggeredAt,
      @HiveField(3) required this.message,
      @HiveField(4) this.isRead = false,
      @HiveField(5) this.metadataJson = '{}'});

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final AlertType type;
  @override
  @HiveField(2)
  final DateTime triggeredAt;
  @override
  @HiveField(3)
  final String message;
  @override
  @JsonKey()
  @HiveField(4)
  final bool isRead;

  /// JSON-encoded metadata string to avoid Hive `Map<String,dynamic>` type issues.
  @override
  @JsonKey()
  @HiveField(5)
  final String metadataJson;

  @override
  String toString() {
    return 'AlertRecord(id: $id, type: $type, triggeredAt: $triggeredAt, message: $message, isRead: $isRead, metadataJson: $metadataJson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlertRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.triggeredAt, triggeredAt) ||
                other.triggeredAt == triggeredAt) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.metadataJson, metadataJson) ||
                other.metadataJson == metadataJson));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, type, triggeredAt, message, isRead, metadataJson);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AlertRecordImplCopyWith<_$AlertRecordImpl> get copyWith =>
      __$$AlertRecordImplCopyWithImpl<_$AlertRecordImpl>(this, _$identity);
}

abstract class _AlertRecord implements AlertRecord {
  const factory _AlertRecord(
      {@HiveField(0) required final String id,
      @HiveField(1) required final AlertType type,
      @HiveField(2) required final DateTime triggeredAt,
      @HiveField(3) required final String message,
      @HiveField(4) final bool isRead,
      @HiveField(5) final String metadataJson}) = _$AlertRecordImpl;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  AlertType get type;
  @override
  @HiveField(2)
  DateTime get triggeredAt;
  @override
  @HiveField(3)
  String get message;
  @override
  @HiveField(4)
  bool get isRead;
  @override

  /// JSON-encoded metadata string to avoid Hive `Map<String,dynamic>` type issues.
  @HiveField(5)
  String get metadataJson;
  @override
  @JsonKey(ignore: true)
  _$$AlertRecordImplCopyWith<_$AlertRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
