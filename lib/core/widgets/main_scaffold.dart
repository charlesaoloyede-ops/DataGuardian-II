import 'package:flutter/material.dart';
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

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const _tabs = [
    RouteNames.dashboard,
    RouteNames.appUsage,
    RouteNames.backgroundUsage,
    RouteNames.alertsCenter,
    RouteNames.topUp,
  ];

  @override
  void initState() {
    super.initState();
    // One launch-time check for a sideloaded update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybePromptUpdate(context);
    });
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
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
