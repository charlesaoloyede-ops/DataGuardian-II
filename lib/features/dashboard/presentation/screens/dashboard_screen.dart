import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/app_icon_widget.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../app_usage/domain/entities/app_usage_record.dart';
import '../../../app_usage/domain/entities/daily_usage_summary.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  static const _usageChannel = MethodChannel(AppConstants.usageStatsChannel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns from granting usage access in Settings.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(dashboardSummaryProvider);
    }
  }

  Future<void> _openUsageAccessSettings() async {
    try {
      await _usageChannel.invokeMethod('openUsageAccessSettings');
    } catch (_) {
      // No settings screen available — nothing more we can do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Guardian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.goNamed(RouteNames.alertsCenter),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.goNamed(RouteNames.settings),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          error: e,
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
          onOpenSettings: _openUsageAccessSettings,
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (summary.hasAnomaly) const _AnomalyBanner(),
              _BillingCycleCard(summary: summary),
              const SizedBox(height: 16),
              _SevenDayChart(days: summary.last7Days),
              const SizedBox(height: 16),
              _TopAppsCard(apps: summary.topApps),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Anomaly Banner ────────────────────────────────────────────────────────────

class _AnomalyBanner extends StatelessWidget {
  const _AnomalyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDataColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.backgroundDataColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.backgroundDataColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unusual data usage detected in the last 7 days.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.backgroundDataColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Billing Cycle Card ────────────────────────────────────────────────────────

class _BillingCycleCard extends StatelessWidget {
  final dynamic summary; // DashboardSummary
  const _BillingCycleCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final used = summary.billingCycleMobileBytes as int;
    final limit = summary.billingCycleMobileLimit as int?;
    final fraction = summary.billingCycleUsageFraction as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Billing Cycle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )),
                Icon(Icons.phone_android_rounded,
                    size: 20, color: AppTheme.mobileDataColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              used.formattedBytes,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
            ),
            if (limit != null) ...[
              const SizedBox(height: 4),
              Text(
                'of ${limit.formattedBytes} limit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (limit != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  color: fraction > 0.9
                      ? scheme.error
                      : AppTheme.mobileDataColor,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(fraction * 100).toStringAsFixed(0)}% used',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 7-Day Line Chart ──────────────────────────────────────────────────────────

class _SevenDayChart extends StatelessWidget {
  final List<DailyUsageSummary> days;
  const _SevenDayChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 Days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: days.isEmpty
                  ? Center(
                      child: Text('No data yet',
                          style: TextStyle(color: scheme.onSurfaceVariant)))
                  : LineChart(_buildChartData(context)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];

    for (var i = 0; i < days.length; i++) {
      final mb = days[i].totalMobileBytes / (1000 * 1000);
      spots.add(FlSpot(i.toDouble(), mb));
    }

    final maxY = spots.isEmpty
        ? 100.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChartData(
      minX: 0,
      maxX: (days.length - 1).toDouble().clamp(0, 6),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) => FlLine(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (v, _) => Text(
              v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}G' : '${v.toStringAsFixed(0)}M',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
              final d = days[idx].date;
              const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  names[d.weekday - 1],
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          // Straight segments: a curved line's bezier overshoot exaggerates
          // peaks and can dip below zero between points, misrepresenting usage.
          isCurved: false,
          color: AppTheme.mobileDataColor,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.mobileDataColor.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

// ── Top Apps Card ─────────────────────────────────────────────────────────────

class _TopAppsCard extends StatelessWidget {
  final List<AppUsageRecord> apps;
  const _TopAppsCard({required this.apps});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxBytes = apps.isEmpty
        ? 1
        : apps.map((a) => a.totalMobileBytes).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Top Apps',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.appUsage),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          if (apps.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No usage data yet',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              itemBuilder: (_, i) =>
                  _TopAppTile(app: apps[i], maxBytes: maxBytes),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TopAppTile extends StatelessWidget {
  final AppUsageRecord app;
  final int maxBytes;
  const _TopAppTile({required this.app, required this.maxBytes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction =
        maxBytes > 0 ? (app.totalMobileBytes / maxBytes).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AppIconWidget(iconBase64: app.appIconBase64, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.appName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    color: AppTheme.mobileDataColor,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            app.totalMobileBytes.formattedBytes,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────


class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isPermission = error.toString().contains('USAGE_ACCESS_REQUIRED');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission ? Icons.security_rounded : Icons.error_outline_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isPermission
                  ? 'Usage access permission is required'
                  : 'Failed to load data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (isPermission) ...[
              const SizedBox(height: 8),
              Text(
                'Data Guardian needs usage access to read your data usage. '
                'Grant it in Settings, then return to the app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isPermission ? onOpenSettings : onRetry,
              child: Text(isPermission ? 'Go to Settings' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

