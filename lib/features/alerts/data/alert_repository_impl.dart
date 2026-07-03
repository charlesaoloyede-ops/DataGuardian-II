import 'package:injectable/injectable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/hive_service.dart';
import '../domain/entities/alert_record.dart';
import '../domain/i_alert_repository.dart';

@LazySingleton(as: IAlertRepository)
class AlertRepositoryImpl implements IAlertRepository {
  final HiveService _hive;
  AlertRepositoryImpl(this._hive);

  @override
  Future<List<AlertRecord>> getAlerts({int limit = 50}) async {
    final box = _hive.alertsBox;
    final all = box.values.toList()
      ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return all.take(limit).toList();
  }

  @override
  Future<void> saveAlert(AlertRecord alert) async {
    final box = _hive.alertsBox;
    await box.put(alert.id, alert);
    // Purge oldest if over limit
    if (box.length > AppConstants.alertHistoryLimit) {
      final sorted = box.values.toList()
        ..sort((a, b) => a.triggeredAt.compareTo(b.triggeredAt));
      final toDelete = sorted.take(box.length - AppConstants.alertHistoryLimit);
      for (final r in toDelete) {
        await box.delete(r.id);
      }
    }
  }

  @override
  Future<void> markAllRead() async {
    final box = _hive.alertsBox;
    final updated = box.values.map((r) => r.copyWith(isRead: true)).toList();
    for (final r in updated) {
      await box.put(r.id, r);
    }
  }

  @override
  Stream<List<AlertRecord>> watchAlerts() {
    return _hive.alertsBox.watch().map((_) {
      final all = _hive.alertsBox.values.toList()
        ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
      return all;
    });
  }
}
