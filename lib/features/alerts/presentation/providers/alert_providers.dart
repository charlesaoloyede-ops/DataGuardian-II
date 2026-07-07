import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/alert_record.dart';
import '../../domain/i_alert_repository.dart';

final alertsStreamProvider = StreamProvider.autoDispose<List<AlertRecord>>((ref) {
  return getIt<IAlertRepository>().watchAlerts();
});
