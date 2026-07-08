// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedbackSubmissionImpl _$$FeedbackSubmissionImplFromJson(
        Map<String, dynamic> json) =>
    _$FeedbackSubmissionImpl(
      message: json['message'] as String,
      category: $enumDecode(_$FeedbackCategoryEnumMap, json['category']),
      email: json['email'] as String?,
      installId: json['installId'] as String,
      appVersion: json['appVersion'] as String,
      platform: json['platform'] as String? ?? 'android',
      osVersion: json['osVersion'] as String?,
      deviceModel: json['deviceModel'] as String?,
      createdAtIso: json['createdAtIso'] as String,
    );

Map<String, dynamic> _$$FeedbackSubmissionImplToJson(
        _$FeedbackSubmissionImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'category': _$FeedbackCategoryEnumMap[instance.category]!,
      'email': instance.email,
      'installId': instance.installId,
      'appVersion': instance.appVersion,
      'platform': instance.platform,
      'osVersion': instance.osVersion,
      'deviceModel': instance.deviceModel,
      'createdAtIso': instance.createdAtIso,
    };

const _$FeedbackCategoryEnumMap = {
  FeedbackCategory.bug: 'bug',
  FeedbackCategory.suggestion: 'suggestion',
  FeedbackCategory.question: 'question',
  FeedbackCategory.praise: 'praise',
  FeedbackCategory.other: 'other',
};
