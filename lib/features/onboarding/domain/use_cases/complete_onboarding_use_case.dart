import 'package:injectable/injectable.dart';
import '../i_onboarding_repository.dart';

@injectable
class CompleteOnboardingUseCase {
  final IOnboardingRepository _repository;
  const CompleteOnboardingUseCase(this._repository);

  Future<void> call() => _repository.completeOnboarding();
}
