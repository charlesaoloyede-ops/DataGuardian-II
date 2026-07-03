import 'package:injectable/injectable.dart';
import '../entities/alert_record.dart';
import '../i_alert_repository.dart';

@injectable
class GetAlertsUseCase {
  final IAlertRepository _repository;
  const GetAlertsUseCase(this._repository);

  Future<List<AlertRecord>> call({int limit = 50}) =>
      _repository.getAlerts(limit: limit);

  Stream<List<AlertRecord>> watch() => _repository.watchAlerts();
}
