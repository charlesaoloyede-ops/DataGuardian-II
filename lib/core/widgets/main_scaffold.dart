import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_names.dart';
import '../../features/app_update/presentation/update_flow.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with WidgetsBindingObserver {
  static const _tabs = [
    RouteNames.dashboard,
    RouteNames.appUsage,
    RouteNames.backgroundUsage,
    RouteNames.alertsCenter,
    RouteNames.topUp,
  ];

  static const _monitorChannel = MethodChannel('com.dataguardian/monitor');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // If opened cold from a conversion-nudge notification, jump to that page.
      // (promptUpdate:false — the launch-time check just below already covers
      // the update sheet on a cold start, so avoid showing it twice.)
      await _consumeLaunchRoute();
      // One launch-time check for a sideloaded update.
      if (mounted) maybePromptUpdate(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A notification tap while the app is already alive delivers via
    // onNewIntent (not initState), so re-check the pending route on resume.
    // A notification tap while the app is already alive resumes it; re-check the
    // pending route and, for the update sentinel, show the sheet (the cold-start
    // path handles that via the launch-time check instead).
    if (state == AppLifecycleState.resumed) {
      _consumeLaunchRoute(promptUpdate: true);
    }
  }

  Future<void> _consumeLaunchRoute({bool promptUpdate = false}) async {
    try {
      final route =
          await _monitorChannel.invokeMethod<String>('consumeLaunchRoute');
      if (route == null || route.isEmpty || !mounted) return;
      if (route == '__check_update__') {
        // Not a real route — the app-update notification asks for the sheet.
        if (promptUpdate) maybePromptUpdate(context);
        return;
      }
      context.go(route);
    } catch (_) {
      // No native channel / nothing pending — ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int index = _tabs.indexWhere((r) => location.startsWith(_pathFor(r)));
    if (index < 0) index = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.goNamed(_tabs[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'App Usage',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud_rounded),
            label: 'Background',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Top Up',
          ),
        ],
      ),
    );
  }

  String _pathFor(String routeName) => switch (routeName) {
        RouteNames.dashboard => '/dashboard',
        RouteNames.appUsage => '/app-usage',
        RouteNames.backgroundUsage => '/background-usage',
        RouteNames.alertsCenter => '/alerts',
        RouteNames.topUp => '/top-up',
        _ => '/dashboard',
      };
}
