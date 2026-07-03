import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const DataGuardianApp());

class DataGuardianApp extends StatelessWidget {
  const DataGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Guardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF216869)),
        useMaterial3: true,
      ),
      home: const UsageAccessScreen(),
    );
  }
}

class AndroidUsageApi {
  static const MethodChannel _channel = MethodChannel('data_guardian/usage');

  static Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;

  static Future<void> openPermissionSettings() =>
      _channel.invokeMethod<void>('openUsageAccessSettings');

  static Future<AppUsagePage> loadUsagePage({
    required int offset,
    required int limit,
    bool reset = false,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('getAppUsagePage', {
      'offset': offset,
      'limit': limit,
      'reset': reset,
    });
    final items = (raw?['items'] as List<dynamic>? ?? const [])
        .map((item) => AppUsage.fromMap(Map<Object?, Object?>.from(item as Map)))
        .toList(growable: false);
    return AppUsagePage(items: items, total: raw?['total'] as int? ?? items.length);
  }

  static Future<void> setAppBudget(String packageName, int? budgetBytes) =>
      _channel.invokeMethod<void>('setAppBudget', {
        'packageName': packageName,
        'budgetBytes': budgetBytes,
      });

  static Future<Map<String, int>> getAppBudgets() async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('getAppBudgets') ?? const {};
    return raw.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;

  static Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');

  static Future<bool> hasNotificationPermission() async =>
      await _channel.invokeMethod<bool>('hasNotificationPermission') ?? false;

  static Future<void> requestNotificationPermission() =>
      _channel.invokeMethod<void>('requestNotificationPermission');

  static Future<void> openAppDetailsSettings() =>
      _channel.invokeMethod<void>('openAppDetailsSettings');
}

class AppUsagePage {
  const AppUsagePage({required this.items, required this.total});

  final List<AppUsage> items;
  final int total;
}

class AppUsage {
  const AppUsage({
    required this.name,
    required this.packageName,
    required this.mobileBytes,
    this.iconBytes,
  });

  factory AppUsage.fromMap(Map<Object?, Object?> map) {
    final icon = map['icon'] as String?;
    return AppUsage(
      name: map['name'] as String? ?? map['packageName'] as String? ?? 'Unknown',
      packageName: map['packageName'] as String? ?? '',
      mobileBytes: (map['mobileBytes'] as num?)?.toInt() ?? 0,
      iconBytes: icon == null || icon.isEmpty ? null : base64Decode(icon),
    );
  }

  final String name;
  final String packageName;
  final int mobileBytes;
  final Uint8List? iconBytes;
}

class UsageAccessScreen extends StatefulWidget {
  const UsageAccessScreen({super.key});

  @override
  State<UsageAccessScreen> createState() => _UsageAccessScreenState();
}

class _UsageAccessScreenState extends State<UsageAccessScreen>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _openingSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openingSettings) {
      _openingSettings = false;
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    if (mounted) setState(() => _checking = true);
    try {
      final allowed = await AndroidUsageApi.hasPermission();
      if (!mounted) return;
      if (allowed) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AppUsageScreen()),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) _showError(error.message ?? 'Could not check usage access.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _requestPermission() async {
    _openingSettings = true;
    try {
      await AndroidUsageApi.openPermissionSettings();
    } on PlatformException catch (error) {
      _openingSettings = false;
      if (mounted) _showError(error.message ?? 'Could not open Android settings.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Guardian')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.data_usage_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Usage access required',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Allow Data Guardian to read network usage so it can show mobile data used by each installed app.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _checking ? null : _requestPermission,
                  icon: _checking
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.settings_rounded),
                  label: Text(_checking ? 'Checking…' : 'Open usage access'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  static const _firstPageSize = 10;
  static const _nextPageSize = 30;

  final List<AppUsage> _apps = [];
  Map<String, int> _budgets = const {};
  int _total = 0;
  bool _initialLoading = true;
  bool _loadingMore = false;
  Object? _error;
  bool _needsBackgroundSetup = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _loadBudgets();
    _checkBackgroundSetup();
  }

  Future<void> _loadBudgets() async {
    final budgets = await AndroidUsageApi.getAppBudgets();
    if (mounted) setState(() => _budgets = budgets);
  }

  Future<void> _checkBackgroundSetup() async {
    final ignoringOptimizations = await AndroidUsageApi.isIgnoringBatteryOptimizations();
    final hasNotifications = await AndroidUsageApi.hasNotificationPermission();
    if (mounted) {
      setState(() => _needsBackgroundSetup = !ignoringOptimizations || !hasNotifications);
    }
  }

  Future<void> _setupBackgroundMonitoring() async {
    await AndroidUsageApi.requestNotificationPermission();
    await AndroidUsageApi.requestIgnoreBatteryOptimizations();
    await _checkBackgroundSetup();
  }

  Future<void> _editBudget(AppUsage app) async {
    final currentBudget = _budgets[app.packageName];
    final controller = TextEditingController(
      text: currentBudget == null ? '' : (currentBudget / 1000000).toStringAsFixed(0),
    );
    final result = await showDialog<_BudgetDialogResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${app.name} data budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly budget (MB)',
            helperText: 'Get alerted at 80%, 90% and 100% of this amount.',
          ),
        ),
        actions: [
          if (currentBudget != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(_BudgetDialogResult.clear),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_BudgetDialogResult.cancel),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_BudgetDialogResult.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == _BudgetDialogResult.clear) {
      await AndroidUsageApi.setAppBudget(app.packageName, null);
      await _loadBudgets();
    } else if (result == _BudgetDialogResult.save) {
      final mb = int.tryParse(controller.text.trim());
      if (mb != null && mb > 0) {
        await AndroidUsageApi.setAppBudget(app.packageName, mb * 1000000);
        await _loadBudgets();
      }
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = null;
      _apps.clear();
      _total = 0;
    });
    try {
      final page = await AndroidUsageApi.loadUsagePage(
        offset: 0,
        limit: _firstPageSize,
        reset: true,
      );
      if (!mounted) return;
      setState(() {
        _apps.addAll(page.items);
        _total = page.total;
        _initialLoading = false;
      });
      unawaited(_loadRemaining());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadRemaining() async {
    while (mounted && _apps.length < _total) {
      setState(() => _loadingMore = true);
      try {
        final page = await AndroidUsageApi.loadUsagePage(
          offset: _apps.length,
          limit: _nextPageSize,
        );
        if (!mounted) return;
        if (page.items.isEmpty) break;
        setState(() => _apps.addAll(page.items));
      } catch (_) {
        // The top apps are already visible; stop background loading silently.
        break;
      }
    }
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed apps'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadInitial,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_initialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            final message = _error is PlatformException
                ? (_error! as PlatformException).message
                : _error.toString();
            return _ErrorView(message: message ?? 'Could not load app usage', onRetry: _loadInitial);
          }

          final apps = _apps;
          if (apps.isEmpty) {
            return const Center(child: Text('No installed apps found.'));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_needsBackgroundSetup)
                Container(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Allow background monitoring to get budget and usage-spike alerts.',
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonal(
                            onPressed: _setupBackgroundMonitoring,
                            child: const Text('Allow'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Android can quietly remove the usage-access permission if Data '
                              "Guardian sits unopened for months. In the app's settings, turn off "
                              '"Remove permissions if app isn\'t used" to keep it active.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: AndroidUsageApi.openAppDetailsSettings,
                            child: const Text('App settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: const Text(
                  'Mobile data used since the start of this month • tap an app to set a budget',
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadInitial,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: apps.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      if (index >= apps.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final app = apps[index];
                      return _AppUsageTile(
                        app: app,
                        budgetBytes: _budgets[app.packageName],
                        onTap: () => _editBudget(app),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _BudgetDialogResult { save, clear, cancel }

class _AppUsageTile extends StatelessWidget {
  const _AppUsageTile({required this.app, required this.budgetBytes, required this.onTap});

  final AppUsage app;
  final int? budgetBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = app.iconBytes;
    final budget = budgetBytes;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: icon == null
          ? const CircleAvatar(child: Icon(Icons.android_rounded))
          : Image.memory(icon, width: 42, height: 42, errorBuilder: (_, __, ___) {
              return const CircleAvatar(child: Icon(Icons.android_rounded));
            }),
      title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: budget == null
          ? Text(app.packageName, maxLines: 1, overflow: TextOverflow.ellipsis)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(app.packageName, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (app.mobileBytes / budget).clamp(0, 1).toDouble(),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
      isThreeLine: budget != null,
      trailing: Text(
        _formatBytes(app.mobileBytes),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1000) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final digits = value >= 100 ? 0 : value >= 10 ? 1 : 2;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
