abstract class IOnboardingRepository {
  bool get isComplete;
  Future<void> completeOnboarding();
  int? get billingCycleStartDay;
  Future<void> setBillingCycleStartDay(int day);
}
