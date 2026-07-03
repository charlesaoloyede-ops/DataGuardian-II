import 'package:flutter/material.dart';

/// Dashboard — Phase 5 implementation.
/// Placeholder until core screen work begins.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Guardian')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.data_usage_rounded, size: 56),
            SizedBox(height: 16),
            Text('Dashboard — coming in Phase 5'),
          ],
        ),
      ),
    );
  }
}
