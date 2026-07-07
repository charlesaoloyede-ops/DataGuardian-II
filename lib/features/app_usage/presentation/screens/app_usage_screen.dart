import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/extensions/int_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_range_utils.dart';
import '../../../../core/widgets/app_icon_widget.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/app_usage_record.dart';
import '../../domain/use_cases/get_app_usage_use_case.dart';
import '../providers/app_usage_providers.dart';

// Provider for per-app budgets (packageName → bytes, mobile only)
final appBudgetsProvider = StateProvider<Map<String, int>>(
    (ref) => getIt<SharedPrefsService>().getAppBudgets());

class AppUsageScreen extends ConsumerWidget {
  const AppUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible    = ref.watch(visibleNetworksProvider);
    final filter     = ref.watch(appUsageFilterProvider);
    final usageAsync = ref.watch(appUsageListProvider);
    final billingDay =
        getIt<SharedPrefsService>().getPreferences().billingCycleStartDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              _FilterChips(
                selected: filter,
                billingStartDay: billingDay,
                onChanged: (f) =>
                    ref.read(appUsageFilterProvider.notifier).state = f,
              ),
              const SizedBox(height: 8),
              _NetworkToggle(
                visible: visible,
                onToggle: (view) {
                  final current = Set<NetworkView>.from(visible);
                  if (current.contains(view)) {
                    current.remove(view);
                  } else {
                    current.add(view);
                  }
                  ref.read(visibleNetworksProvider.notifier).state = current;
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: usageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => e is NetworkStatsRestrictedException
            ? const _OemRestrictionBanner()
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48),
                    const SizedBox(height: 12),
                    Text(e.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () => invalidateAppUsage(ref),
                        child: const Text('Retry')),
                  ],
                ),
              ),
        data: (apps) => apps.isEmpty
            ? _EmptyState(visible: visible)
            : RefreshIndicator(
                onRefresh: () async => invalidateAppUsage(ref),
                child: _AppList(apps: apps, visible: visible),
              ),
      ),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final DateRangeFilter selected;
  final int billingStartDay;
  final ValueChanged<DateRangeFilter> onChanged;
  const _FilterChips({
    required this.selected,
    required this.billingStartDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip('Today', DateFilterPreset.today,
              () => onChanged(DateRangeFilter.today())),
          const SizedBox(width: 8),
          _chip('7 Days', DateFilterPreset.last7Days,
              () => onChanged(DateRangeFilter.last7Days())),
          const SizedBox(width: 8),
          _chip('Billing Cycle', DateFilterPreset.billingCycle, () {
            final day = billingStartDay > 0 ? billingStartDay : null;
            onChanged(DateRangeFilter.billingCycle(day));
          }),
          const SizedBox(width: 8),
          _customChip(context),
        ],
      ),
    );
  }

  Widget _chip(String label, DateFilterPreset preset, VoidCallback onTap) {
    final isSelected = selected.preset == preset;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _customChip(BuildContext context) {
    final isSelected = selected.preset == DateFilterPreset.custom;
    return FilterChip(
      label: Text(isSelected ? selected.label : 'Custom'),
      selected: isSelected,
      avatar: const Icon(Icons.date_range_rounded, size: 16),
      onSelected: (_) async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateRangeFilter.earliestAllowed,
          lastDate: DateTime.now(),
          initialDateRange: isSelected
              ? DateTimeRange(start: selected.start, end: selected.end)
              : null,
        );
        if (range != null) onChanged(DateRangeFilter.fromDateRange(range));
      },
    );
  }
}

// ── Network Toggle (independent checkboxes) ───────────────────────────────────

class _NetworkToggle extends StatelessWidget {
  final Set<NetworkView> visible;
  final ValueChanged<NetworkView> onToggle;
  const _NetworkToggle({required this.visible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip(context, NetworkView.mobile, Icons.phone_android_rounded,
              'Mobile', AppTheme.mobileDataColor),
          const SizedBox(width: 10),
          _chip(context, NetworkView.wifi, Icons.wifi_rounded, 'Wi-Fi',
              AppTheme.wifiDataColor),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, NetworkView view, IconData icon,
      String label, Color color) {
    final on = visible.contains(view);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onToggle(view),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? color : scheme.outline.withValues(alpha: 0.4),
            width: on ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: on ? color : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 14, color: on ? color : scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                color: on ? color : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App List ──────────────────────────────────────────────────────────────────

class _AppList extends ConsumerWidget {
  final List<AppUsageRecord> apps;
  final Set<NetworkView> visible;
  const _AppList({required this.apps, required this.visible});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets  = ref.watch(appBudgetsProvider);
    final personal = apps.where((a) => !a.isSystemApp).toList();
    final system   = apps.where((a) =>  a.isSystemApp).toList();

    final showMobile = visible.contains(NetworkView.mobile);
    final showWifi   = visible.contains(NetworkView.wifi);

    final totalMobile = showMobile ? apps.fold(0, (s, a) => s + a.totalMobileBytes) : 0;
    final totalWifi   = showWifi   ? apps.fold(0, (s, a) => s + a.totalWifiBytes)   : 0;

    // Max visible bytes across all apps — scales the progress bars.
    final maxBytes = apps.map((a) {
      var b = 0;
      if (showMobile) b += a.totalMobileBytes;
      if (showWifi)   b += a.totalWifiBytes;
      return b;
    }).fold(1, (a, b) => a > b ? a : b);

    return ListView(
      children: [
        _TotalSummaryCard(
          totalMobile: totalMobile,
          totalWifi: totalWifi,
          showMobile: showMobile,
          showWifi: showWifi,
        ),
        const _BudgetHint(),
        if (personal.isNotEmpty) ...[
          _SectionHeader(title: 'Personal Apps', count: personal.length),
          ...personal.map((a) => _AppTile(
                app: a,
                maxBytes: maxBytes,
                showMobile: showMobile,
                showWifi: showWifi,
                budgetBytes: budgets[a.packageName],
                onBudgetChanged: (newBudget) =>
                    _saveBudget(ref, a.packageName, newBudget, budgets),
              )),
        ],
        if (system.isNotEmpty) ...[
          _SectionHeader(title: 'System Apps', count: system.length),
          ...system.map((a) => _AppTile(
                app: a,
                maxBytes: maxBytes,
                showMobile: showMobile,
                showWifi: showWifi,
                budgetBytes: budgets[a.packageName],
                onBudgetChanged: (newBudget) =>
                    _saveBudget(ref, a.packageName, newBudget, budgets),
              )),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _saveBudget(WidgetRef ref, String packageName, int? budget,
      Map<String, int> current) {
    final updated = Map<String, int>.from(current);
    if (budget == null || budget <= 0) {
      updated.remove(packageName);
    } else {
      updated[packageName] = budget;
    }
    ref.read(appBudgetsProvider.notifier).state = updated;
    getIt<SharedPrefsService>().saveAppBudgets(updated);
  }
}

// ── Total Summary Card ────────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  final int totalMobile;
  final int totalWifi;
  final bool showMobile;
  final bool showWifi;
  const _TotalSummaryCard({
    required this.totalMobile,
    required this.totalWifi,
    required this.showMobile,
    required this.showWifi,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <Widget>[];

    if (showMobile) {
      items.add(Expanded(
        child: _StatItem(
          label: 'Mobile',
          bytes: totalMobile,
          color: AppTheme.mobileDataColor,
          icon: Icons.phone_android_rounded,
        ),
      ));
    }
    if (showMobile && showWifi) {
      items.add(Container(width: 1, height: 40, color: scheme.outlineVariant));
    }
    if (showWifi) {
      items.add(Expanded(
        child: _StatItem(
          label: 'Wi-Fi',
          bytes: totalWifi,
          color: AppTheme.wifiDataColor,
          icon: Icons.wifi_rounded,
        ),
      ));
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: items),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int bytes;
  final Color color;
  final IconData icon;
  const _StatItem(
      {required this.label,
      required this.bytes,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Text(bytes.formattedBytes,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Budget Hint ───────────────────────────────────────────────────────────────

class _BudgetHint extends StatelessWidget {
  const _BudgetHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tap an app to set a data budget and get notified as you approach it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(width: 6),
          Text('($count)',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

// ── App Tile ──────────────────────────────────────────────────────────────────

class _AppTile extends StatelessWidget {
  final AppUsageRecord app;
  final int maxBytes;
  final bool showMobile;
  final bool showWifi;
  final int? budgetBytes;
  final ValueChanged<int?> onBudgetChanged;

  const _AppTile({
    required this.app,
    required this.maxBytes,
    required this.showMobile,
    required this.showWifi,
    required this.budgetBytes,
    required this.onBudgetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = showMobile ? app.totalMobileBytes : 0;
    final wifi   = showWifi   ? app.totalWifiBytes   : 0;
    final total  = mobile + wifi;

    // Fraction of the widest bar in the list.
    final totalFrac  = maxBytes > 0 ? (total / maxBytes).clamp(0.0, 1.0) : 0.0;
    final mobileFrac = total > 0 ? (mobile / total).clamp(0.0, 1.0) : 0.0;

    // Budget tracks mobile data only.
    final budget     = budgetBytes;
    final budgetFrac = budget != null && budget > 0 && showMobile
        ? (app.totalMobileBytes / budget).clamp(0.0, 1.0)
        : null;
    final budgetOver = (budgetFrac ?? 0) >= 1.0;

    return InkWell(
      onTap: () => _showBudgetSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AppIconWidget(iconBase64: app.appIconBase64, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name + total bytes
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        total.formattedBytes,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Stacked bar — mobile (blue) always first, wifi (green) after
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(color: scheme.surfaceContainerHighest),
                          FractionallySizedBox(
                            widthFactor: totalFrac,
                            child: Row(
                              children: [
                                if (showMobile && mobile > 0)
                                  Flexible(
                                    flex: (mobileFrac * 1000).toInt().clamp(1, 999),
                                    child: Container(color: AppTheme.mobileDataColor),
                                  ),
                                if (showWifi && wifi > 0)
                                  Flexible(
                                    flex: ((1 - mobileFrac) * 1000).toInt().clamp(1, 999),
                                    child: Container(color: AppTheme.wifiDataColor),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Mobile + wifi byte labels + budget badge
                  Row(
                    children: [
                      if (showMobile) ...[
                        _dot(AppTheme.mobileDataColor),
                        const SizedBox(width: 3),
                        Text(mobile.formattedBytes,
                            style: TextStyle(
                                fontSize: 10, color: scheme.onSurfaceVariant)),
                      ],
                      if (showMobile && showWifi) const SizedBox(width: 8),
                      if (showWifi) ...[
                        _dot(AppTheme.wifiDataColor),
                        const SizedBox(width: 3),
                        Text(wifi.formattedBytes,
                            style: TextStyle(
                                fontSize: 10, color: scheme.onSurfaceVariant)),
                      ],
                      const Spacer(),
                      if (budgetFrac != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: (budgetOver ? scheme.error : scheme.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(budgetFrac * 100).toStringAsFixed(0)}% of limit',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: budgetOver ? scheme.error : scheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Budget bar — extra padding above it
                  if (budgetFrac != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: budgetFrac,
                        minHeight: 4,
                        color: budgetOver ? scheme.error : scheme.primary,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${app.totalMobileBytes.formattedBytes} of ${budget!.formattedBytes} mobile limit',
                      style:
                          TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  void _showBudgetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetSheet(
        appName: app.appName,
        currentBudgetBytes: budgetBytes,
        onSave: onBudgetChanged,
      ),
    );
  }
}

// ── Budget Bottom Sheet ───────────────────────────────────────────────────────

class _BudgetSheet extends StatefulWidget {
  final String appName;
  final int? currentBudgetBytes;
  final ValueChanged<int?> onSave;
  const _BudgetSheet(
      {required this.appName,
      required this.currentBudgetBytes,
      required this.onSave});

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final mb =
        widget.currentBudgetBytes != null && widget.currentBudgetBytes! > 0
            ? (widget.currentBudgetBytes! / (1000 * 1000)).toStringAsFixed(0)
            : '';
    _ctrl = TextEditingController(text: mb);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 24,
          right: 24,
          top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mobile data budget — ${widget.appName}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Sets a limit on mobile data only. Wi-Fi usage is not counted.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile budget (MB)',
              suffixText: 'MB',
              border: OutlineInputBorder(),
              hintText: 'e.g. 500',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.currentBudgetBytes != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onSave(null);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Remove limit'),
                  ),
                ),
              if (widget.currentBudgetBytes != null) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final v = double.tryParse(_ctrl.text.trim());
                    widget.onSave(
                        v != null && v > 0 ? (v * 1000 * 1000).toInt() : null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── OEM Restriction ───────────────────────────────────────────────────────────

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
            Icon(Icons.lock_outline_rounded,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Per-app data unavailable',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your device manufacturer restricts access to per-app network statistics. '
              'Total usage is shown on the Dashboard.',
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
  final Set<NetworkView> visible;
  const _EmptyState({required this.visible});

  @override
  Widget build(BuildContext context) {
    final label = visible.isEmpty
        ? 'No network selected.'
        : visible.length == 1
            ? 'No ${visible.first == NetworkView.mobile ? 'mobile' : 'Wi-Fi'} usage in the selected period.'
            : 'No usage data in the selected period.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            label,
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
