import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/feedback_thread.dart';
import '../providers/feedback_providers.dart';

class MyFeedbackScreen extends ConsumerStatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  ConsumerState<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends ConsumerState<MyFeedbackScreen> {
  Future<void> _markRepliesSeen(List<FeedbackThread> threads) async {
    final repliedIds = threads.where((t) => t.hasReply).map((t) => t.id).toSet();
    final seen = ref.read(seenReplyIdsProvider);
    final fresh = repliedIds.difference(seen);
    if (fresh.isEmpty) return;
    await getIt<SharedPrefsService>().addSeenReplyIds(fresh);
    ref.read(seenReplyIdsProvider.notifier).state = {...seen, ...fresh};
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myFeedbackProvider);

    // Opening this screen clears the unread badge for any replies now visible.
    final loaded = async.valueOrNull;
    if (loaded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markRepliesSeen(loaded);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your feedback')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _Message(
          'Couldn\'t load your feedback. Check your connection and try again.',
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return const _Message(
              'You haven\'t sent any feedback yet. When you do, replies from the '
              'team will show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ThreadCard(thread: threads[i]),
          );
        },
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final FeedbackThread thread;
  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(thread.category[0].toUpperCase() + thread.category.substring(1),
                  style: textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const Spacer(),
              _StatusPill(thread: thread),
            ],
          ),
          const SizedBox(height: 8),
          Text(thread.message, style: textTheme.bodyMedium),
          if (thread.hasReply) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent_rounded,
                          size: 16, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text('Reply from the team',
                          style: textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(thread.replyText!,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final FeedbackThread thread;
  const _StatusPill({required this.thread});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (thread.status) {
      'replied' => ('Replied', scheme.primary),
      'read' => ('Seen by the team', scheme.tertiary),
      _ => ('Sent', scheme.outline),
    };
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600));
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
