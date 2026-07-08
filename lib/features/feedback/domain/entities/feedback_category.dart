/// Categories a user can tag feedback with. Kept deliberately small so the
/// admin dashboard can triage at a glance. The [name] is the stable wire value
/// stored in Firestore (`bug`, `suggestion`, ...).
enum FeedbackCategory {
  bug,
  suggestion,
  question,
  praise,
  other;

  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case FeedbackCategory.bug:
        return 'Bug';
      case FeedbackCategory.suggestion:
        return 'Suggestion';
      case FeedbackCategory.question:
        return 'Question';
      case FeedbackCategory.praise:
        return 'Praise';
      case FeedbackCategory.other:
        return 'Other';
    }
  }
}
