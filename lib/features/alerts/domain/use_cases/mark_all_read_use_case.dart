import 'package:injectable/injectable.dart';
import '../i_alert_repository.dart';

@injectable
class MarkAllReadUseCase {
  final IAlertRepository _repository;
  const MarkAllReadUseCase(this._repository);

  Future<void> call() => _repository.markAllRead();
}
