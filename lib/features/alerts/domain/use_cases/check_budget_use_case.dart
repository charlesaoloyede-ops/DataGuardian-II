import 'package:injectable/injectable.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../../app_usage/domain/entities/app_usage_record.dart';

/// Threshold percentages checked in descending order, so only the highest
/// newly-crossed threshold is reported per app per call.
const budgetThresholdPercents = [100, 90, 80, 70];

class BudgetBreach {
  const BudgetBreach({
    required this.packageName,
    required this.appName,
    required this.usageBytes,
    required this.budgetBytes,
    required this.thresholdPercent,
  });

  final String packageName;
  final String appName;
  final int usageBytes;
  final int budgetBytes;
  final int thresholdPercent;
}

/// Checks each app's mobile usage (for the current billing cycle) against its
/// user-set budget, reporting a [BudgetBreach] the first time it crosses each
/// of the 70/80/90/100% thresholds. Progress is persisted per billing cycle so
/// the same threshold is never reported twice.
@injectable
class CheckBudgetUseCase {
  final SharedPrefsService _prefs;
  const CheckBudgetUseCase(this._prefs);

  Future<List<BudgetBreach>> call(
    List<AppUsageRecord> apps,
    DateTime billingCycleStart,
  ) async {
    final budgets = _prefs.getAppBudgets();
    if (budgets.isEmpty) return [];

    final cycleKey = billingCycleStart.dayKey;
    final progress = _prefs.budgetAlertCycleKey == cycleKey
        ? _prefs.getBudgetAlertProgress()
        : <String, int>{}; // billing cycle rolled over — reset progress

    final breaches = <BudgetBreach>[];
    for (final app in apps) {
      final budget = budgets[app.packageName];
      if (budget == null || budget <= 0) continue;

      final usagePercent = (app.totalMobileBytes / budget) * 100;
      final lastNotified = progress[app.packageName] ?? 0;

      for (final threshold in budgetThresholdPercents) {
        if (usagePercent >= threshold && lastNotified < threshold) {
          breaches.add(BudgetBreach(
            packageName: app.packageName,
            appName: app.appName,
            usageBytes: app.totalMobileBytes,
            budgetBytes: budget,
            thresholdPercent: threshold,
          ));
          progress[app.packageName] = threshold;
          break;
        }
      }
    }

    await _prefs.saveBudgetAlertProgress(progress);
    await _prefs.setBudgetAlertCycleKey(cycleKey);

    return breaches;
  }
}
