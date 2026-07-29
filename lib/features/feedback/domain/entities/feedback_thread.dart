/// A piece of feedback the user submitted, as read back from Firestore —
/// including the team's reply if one has been posted. Distinct from
/// [FeedbackSubmission] (the write payload); this is the read/display model.
class FeedbackThread {
  final String id;
  final String message;
  final String category;

  /// `new` | `read` | `replied` (server-managed).
  final String status;
  final DateTime createdAt;
  final String? replyText;
  final DateTime? repliedAt;

  const FeedbackThread({
    required this.id,
    required this.message,
    required this.category,
    required this.status,
    required this.createdAt,
    this.replyText,
    this.repliedAt,
  });

  bool get hasReply => replyText != null && replyText!.trim().isNotEmpty;
}
