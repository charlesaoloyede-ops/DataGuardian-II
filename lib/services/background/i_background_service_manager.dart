abstract class IBackgroundServiceManager {
  Future<void> startService();
  Future<void> stopService();
  Future<bool> isRunning();
}
