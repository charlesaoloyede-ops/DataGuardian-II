import 'package:injectable/injectable.dart';
import '../entities/alert_record.dart';
import '../i_alert_repository.dart';

@injectable
class SaveAlertUseCase {
  final IAlertRepository _repository;
  const SaveAlertUseCase(this._repository);

  Future<void> call(AlertRecord alert) => _repository.saveAlert(alert);
}
