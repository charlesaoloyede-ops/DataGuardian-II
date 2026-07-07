import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../core/widgets/app_icon_widget.dart';
import '../../../app_usage/domain/entities/app_usage_record.dart';
import '../../../app_usage/presentation/providers/app_usage_providers.dart';

class BackgroundUsageScreen extends ConsumerWidget {
  const BackgroundUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter      = ref.watch(appUsageFilterProvider);
    final usageAsync  = ref.watch(backgroundUsageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Usage'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterChips(
            selected: filter,
            onChanged: (f) =>
                ref.read(appUsageFilterProvider.notifier).state = f,
          ),
        ),
      ),
      body: usageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is NetworkStatsRestrictedException
            ? const _OemRestrictionBanner()
            : Center(child: Text(e.toString())),
        data: (apps) => apps.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(backgroundUsageProvider),
                child: _BackgroundList(apps: apps),
              ),
      ),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final DateRangeFilter selected;
  final ValueChanged<DateRangeFilter> onChanged;
  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Today'),
            selected: selected.preset == DateFilterPreset.today,
            onSelected: (_) => onChanged(DateRangeFilter.today()),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('7 Days'),
            selected: selected.preset == DateFilterPreset.last7Days,
            onSelected: (_) => onChanged(DateRangeFilter.last7Days()),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Billing Cycle'),
            selected: selected.preset == DateFilterPreset.billingCycle,
            onSelected: (_) => onChanged(DateRangeFilter.billingCycle(null)),
          ),
        ],
      ),
    );
  }
}

// ── Background List ───────────────────────────────────────────────────────────

class _BackgroundList extends StatelessWidget {
  final List<AppUsageRecord> apps;
  const _BackgroundList({required this.apps});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: apps.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _ImpactLegend();
        final app = apps[index - 1];
        final bgBytes = app.mobileBackgroundBytes + app.wifiBackgroundBytes;
        return _BackgroundTile(app: app, bgBytes: bgBytes);
      },
    );
  }
}

class _ImpactLegend extends StatelessWidget {
  const _ImpactLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _legendItem(context, Colors.red.shade400, 'High',
                '> ${AppConstants.highImpactBytes.formattedBytes}'),
            _legendItem(context, AppTheme.backgroundDataColor, 'Medium',
                '> ${AppConstants.mediumImpactBytes.formattedBytes}'),
            _legendItem(
                context, scheme.onSurfaceVariant, 'Low', 'below medium'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(
      BuildContext context, Color color, String label, String range) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Text(range,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final AppUsageRecord app;
  final int bgBytes;
  const _BackgroundTile({required this.app, required this.bgBytes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color impactColor;
    String impactLabel;
    if (bgBytes >= AppConstants.highImpactBytes) {
      impactColor = Colors.red.shade400;
      impactLabel = 'High';
    } else if (bgBytes >= AppConstants.mediumImpactBytes) {
      impactColor = AppTheme.backgroundDataColor;
      impactLabel = 'Medium';
    } else {
      impactColor = scheme.onSurfaceVariant;
      impactLabel = 'Low';
    }

    return ListTile(
      leading: AppIconWidget(iconBase64: app.appIconBase64),
      title: Text(app.appName,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${app.mobileBackgroundBytes.formattedBytes} mobile  ·  ${app.wifiBackgroundBytes.formattedBytes} Wi-Fi',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: impactColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: impactColor.withValues(alpha: 0.4)),
        ),
        child: Text(
          impactLabel,
          style: TextStyle(
              fontSize: 12,
              color: impactColor,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _OemRestrictionBanner extends StatelessWidget {
  const _OemRestrictionBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Per-app data unavailable',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your device manufacturer restricts access to per-app network statistics.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No background data usage\nin the selected period.',
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
