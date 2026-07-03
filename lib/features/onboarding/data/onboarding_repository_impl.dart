import 'package:injectable/injectable.dart';
import '../../../services/storage/shared_prefs_service.dart';
import '../domain/i_onboarding_repository.dart';

@LazySingleton(as: IOnboardingRepository)
class OnboardingRepositoryImpl implements IOnboardingRepository {
  final SharedPrefsService _prefs;
  const OnboardingRepositoryImpl(this._prefs);

  @override
  bool get isComplete => _prefs.onboardingComplete;

  @override
  Future<void> completeOnboarding() => _prefs.setOnboardingComplete(true);

  @override
  int? get billingCycleStartDay {
    final prefs = _prefs.getPreferences();
    return prefs.billingCycleStartDay == -1 ? null : prefs.billingCycleStartDay;
  }

  @override
  Future<void> setBillingCycleStartDay(int day) async {
    final prefs = _prefs.getPreferences();
    await _prefs.savePreferences(prefs.copyWith(billingCycleStartDay: day));
  }
}
