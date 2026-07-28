import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../data/bundle_repository.dart';
import '../../domain/entities/bundle_status.dart';

final bundleRepositoryProvider = Provider<BundleRepository>(
  (ref) => BundleRepository(getIt<SharedPrefsService>()),
);

/// Live status of the monitored bundle (null when none is set up). Watched by
/// the Home card and the bundle screen; invalidate it after any mutation to
/// recompute remaining / runway.
final bundleStatusProvider = FutureProvider.autoDispose<BundleStatus?>(
  (ref) => ref.read(bundleRepositoryProvider).buildStatus(),
);
