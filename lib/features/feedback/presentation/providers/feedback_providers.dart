import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/feedback_thread.dart';
import '../../domain/i_feedback_repository.dart';

/// The current user's feedback threads (with replies), newest first.
final myFeedbackProvider =
    StreamProvider.autoDispose<List<FeedbackThread>>((ref) {
  return getIt<IFeedbackRepository>().watchMyFeedback();
});

/// IDs of replies the user has already seen (persisted). Seeded from prefs and
/// updated when they open the "Your feedback" screen.
final seenReplyIdsProvider = StateProvider<Set<String>>(
  (ref) => getIt<SharedPrefsService>().getSeenReplyIds(),
);

/// Number of replies the user hasn't seen yet — drives the unread badge.
final unreadReplyCountProvider = Provider.autoDispose<int>((ref) {
  final threads = ref.watch(myFeedbackProvider).valueOrNull ?? const [];
  final seen = ref.watch(seenReplyIdsProvider);
  return threads.where((t) => t.hasReply && !seen.contains(t.id)).length;
});
