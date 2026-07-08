import 'package:freezed_annotation/freezed_annotation.dart';
import 'feedback_category.dart';

part 'feedback_submission.freezed.dart';
part 'feedback_submission.g.dart';

/// The full feedback payload as stored (Firestore doc / local pending queue).
///
/// Mirrors the `feedback` collection contract in
/// docs/backend/firestore-schema.md. `status` is written as `new` by the app
/// and only ever changed by the backend, so it is not part of this client
/// payload. `createdAt` is set authoritatively server-side; [createdAtIso] is a
/// client-time fallback kept for the offline queue.
@freezed
class FeedbackSubmission with _$FeedbackSubmission {
  const factory FeedbackSubmission({
    required String message,
    required FeedbackCategory category,
    String? email,
    required String installId,
    required String appVersion,
    @Default('android') String platform,
    String? osVersion,
    String? deviceModel,
    required String createdAtIso,
  }) = _FeedbackSubmission;

  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) =>
      _$FeedbackSubmissionFromJson(json);
}
