import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class UsageAccessDeniedFailure extends Failure {
  const UsageAccessDeniedFailure()
      : super('Usage access permission is required. Please grant it in Settings.');
}

class NetworkStatsRestrictedFailure extends Failure {
  const NetworkStatsRestrictedFailure()
      : super('Per-app data is not available on this device. Showing total usage only.');
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
