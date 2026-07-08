import 'package:injectable/injectable.dart';
import '../entities/feedback_category.dart';
import '../i_feedback_repository.dart';

@lazySingleton
class SubmitFeedbackUseCase {
  final IFeedbackRepository _repo;
  SubmitFeedbackUseCase(this._repo);

  Future<void> call({
    required String message,
    required FeedbackCategory category,
    String? email,
  }) {
    return _repo.submit(message: message, category: category, email: email);
  }
}
