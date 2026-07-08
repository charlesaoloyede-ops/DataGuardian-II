import 'entities/feedback_category.dart';
import 'entities/feedback_thread.dart';

abstract class IFeedbackRepository {
  /// Submits user feedback. [message] is required; [email] is optional and used
  /// only to send a reply. Device/app metadata (install id, app version, etc.)
  /// is attached by the implementation, not the caller.
  Future<void> submit({
    required String message,
    required FeedbackCategory category,
    String? email,
  });

  /// Streams the current user's own feedback (and any replies), newest first.
  /// Emits an empty list when there is no signed-in identity yet.
  Stream<List<FeedbackThread>> watchMyFeedback();
}
