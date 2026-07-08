import 'entities/feedback_category.dart';

abstract class IFeedbackRepository {
  /// Submits user feedback. [message] is required; [email] is optional and used
  /// only to send a reply. Device/app metadata (install id, app version, etc.)
  /// is attached by the implementation, not the caller.
  Future<void> submit({
    required String message,
    required FeedbackCategory category,
    String? email,
  });
}
