abstract class INotificationService {
  Future<void> initialize();
  Future<void> showThresholdAlert({required String title, required String body});
  Future<void> showSpikeAlert({required String title, required String body});
  Future<void> showBackgroundAlert({required String title, required String body});
  Future<bool> requestPermission();
}
