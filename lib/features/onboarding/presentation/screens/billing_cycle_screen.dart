import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';

class BillingCycleScreen extends StatefulWidget {
  const BillingCycleScreen({super.key});

  @override
  State<BillingCycleScreen> createState() => _BillingCycleScreenState();
}

class _BillingCycleScreenState extends State<BillingCycleScreen> {
  int? _selectedDay;

  Future<void> _save() async {
    final prefs = getIt<SharedPrefsService>();
    final p = prefs.getPreferences();
    await prefs.savePreferences(
      p.copyWith(billingCycleStartDay: _selectedDay ?? -1),
    );
    if (mounted) context.goNamed(RouteNames.onboardingComplete);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Step 6 of 6')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('When does your billing cycle start?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'We use this to show your data usage for the current billing period. You can change this anytime in Settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: 28,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final selected = _selectedDay == day;
                  return InkWell(
                    onTap: () => setState(() => _selectedDay = day),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selectedDay != null ? _save : null,
              child: const Text('Save & Continue'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.goNamed(RouteNames.onboardingComplete),
              child: const Text('Skip — use Last 30 Days'),
            ),
          ],
        ),
      ),
    );
  }
}
