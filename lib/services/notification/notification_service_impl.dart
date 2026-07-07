import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/app_constants.dart';
import 'i_notification_service.dart';

@LazySingleton(as: INotificationService)
class NotificationServiceImpl implements INotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.alertChannelId,
      AppConstants.alertChannelName,
      description: 'Alerts for data usage anomalies and thresholds',
      importance: Importance.high,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      AppConstants.monitorChannelId,
      AppConstants.monitorChannelName,
      description: 'Background data monitoring service',
      importance: Importance.low,
    ));
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> showThresholdAlert({required String title, required String body}) =>
      _show(id: 1001, title: title, body: body);

  @override
  Future<void> showSpikeAlert({required String title, required String body}) =>
      _show(id: 1002, title: title, body: body);

  @override
  Future<void> showBackgroundAlert({required String title, required String body}) =>
      _show(id: 1003, title: title, body: body);

  @override
  Future<void> showBudgetAlert({required String title, required String body}) =>
      _show(id: 1004, title: title, body: body);

  Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alertChannelId,
          AppConstants.alertChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
