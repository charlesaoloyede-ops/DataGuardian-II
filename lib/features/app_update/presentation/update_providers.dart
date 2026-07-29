import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../domain/app_release.dart';
import '../domain/i_update_repository.dart';

/// One-shot check for an available update (null when up to date).
final updateCheckProvider = FutureProvider.autoDispose<AppUpdateInfo?>(
  (ref) => getIt<IUpdateRepository>().checkForUpdate(),
);
