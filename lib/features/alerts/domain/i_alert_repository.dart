import 'entities/alert_record.dart';

abstract class IAlertRepository {
  Future<List<AlertRecord>> getAlerts({int limit = 50});
  Future<void> saveAlert(AlertRecord alert);
  Future<void> markAllRead();
  Stream<List<AlertRecord>> watchAlerts();
}
