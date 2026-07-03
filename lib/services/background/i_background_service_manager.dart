abstract class IBackgroundServiceManager {
  Future<void> startService();
  Future<void> stopService();
  bool get isRunning;
}
