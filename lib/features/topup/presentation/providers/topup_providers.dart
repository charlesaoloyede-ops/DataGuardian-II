import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../services/storage/shared_prefs_service.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/data_plan.dart';
import '../../domain/entities/network_provider.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/i_topup_repository.dart';

/// Live data bundles for a network (re-fetched per network selection).
final dataPlansProvider =
    FutureProvider.autoDispose.family<List<DataPlan>, NetworkProvider>(
  (ref, network) => getIt<ITopUpRepository>().getDataPlans(network),
);

/// Live status of a single transaction, by reference.
final purchaseStatusProvider =
    StreamProvider.autoDispose.family<Purchase, String>(
  (ref, reference) => getIt<ITopUpRepository>().watchPurchase(reference),
);

/// The user's purchase history, newest first.
final purchaseHistoryProvider =
    StreamProvider.autoDispose<List<Purchase>>(
  (ref) => getIt<ITopUpRepository>().watchHistory(),
);

/// Saved recipients. Seeded from storage; kept in sync as purchases save new
/// beneficiaries via [BeneficiariesNotifier].
final beneficiariesProvider =
    NotifierProvider<BeneficiariesNotifier, List<Beneficiary>>(
  BeneficiariesNotifier.new,
);

class BeneficiariesNotifier extends Notifier<List<Beneficiary>> {
  @override
  List<Beneficiary> build() => getIt<SharedPrefsService>().getBeneficiaries();

  Future<void> save(Beneficiary b) async {
    await getIt<SharedPrefsService>().saveBeneficiary(b);
    state = getIt<SharedPrefsService>().getBeneficiaries();
  }

  Future<void> remove(String phone) async {
    await getIt<SharedPrefsService>().removeBeneficiary(phone);
    state = getIt<SharedPrefsService>().getBeneficiaries();
  }
}
