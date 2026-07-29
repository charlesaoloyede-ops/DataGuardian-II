import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/analytics/i_analytics_service.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/budget_nudge_banner.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/alert_record.dart';
import '../../domain/entities/alert_type.dart';
import '../../domain/use_cases/mark_all_read_use_case.dart';
import '../providers/alert_providers.dart';

class AlertsCenterScreen extends ConsumerWidget {
  const AlertsCenterScreen({super.key});

  /// True until the user has set all three general data limits (daily, weekly,
  /// and background) — drives the "Set General Data Limit" conversion callout,
  /// which keeps showing until every limit is configured.
  bool _limitsIncomplete() {
    final p = getIt<SharedPrefsService>().getPreferences();
    return p.dailyThresholdBytes == null ||
        p.weeklyThresholdBytes == null ||
        p.backgroundThresholdBytes == null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Alert settings',
            onPressed: () => context.goNamed(RouteNames.alertConfig),
          ),
          alertsAsync.maybeWhen(
            data: (alerts) => alerts.any((a) => !a.isRead)
                ? IconButton(
                    icon: const Icon(Icons.done_all_rounded),
                    tooltip: 'Mark all as read',
                    onPressed: () =>
                        getIt<MarkAllReadUseCase>().call(),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_limitsIncomplete())
            NudgeBanner(
              id: 'limits',
              icon: Icons.speed_rounded,
              title: 'Set General Data Limit',
              message:
                  'Set daily, weekly, and background data limits. Get notified '
                  'when you\'re close to a limit or when usage spikes above your '
                  'normal average.',
              actionLabel: 'Set Data Limit',
              onAction: () => context.goNamed(RouteNames.alertConfig),
            ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (alerts) => alerts.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alert Tile ────────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final AlertRecord alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = _iconForType(alert.type, scheme);

    return ListTile(
      onTap: () => getIt<IAnalyticsService>().logEvent(
        AnalyticsEvents.alertClicked,
        properties: {'type': alert.type.name, 'id': alert.id},
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        alert.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w600,
            ),
      ),
      subtitle: Text(
        _timeAgo(alert.triggeredAt),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: alert.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  (IconData, Color) _iconForType(AlertType type, ColorScheme scheme) =>
      switch (type) {
        AlertType.spike     => (Icons.trending_up_rounded,    const Color(0xFFF59E0B)),
        AlertType.threshold => (Icons.data_usage_rounded,     scheme.error),
        AlertType.background => (Icons.cloud_rounded,         const Color(0xFF1A56DB)),
        AlertType.budget    => (Icons.pie_chart_rounded,      scheme.error),
        AlertType.bundle    => (Icons.data_saver_off_rounded, const Color(0xFFF59E0B)),
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No alerts yet.\nWe\'ll notify you if something unusual happens.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
