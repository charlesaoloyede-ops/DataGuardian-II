import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';
import 'background_service_entrypoint.dart';
import 'i_background_service_manager.dart';

@LazySingleton(as: IBackgroundServiceManager)
class BackgroundServiceManager implements IBackgroundServiceManager {
  final _service = FlutterBackgroundService();
  bool _configured = false;

  Future<void> _configure() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConstants.monitorChannelId,
        initialNotificationTitle: 'Data Guardian',
        initialNotificationContent: 'Monitoring your data usage…',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
    _configured = true;
  }

  @override
  Future<void> startService() async {
    if (!_configured) await _configure();
    await _service.startService();
  }

  @override
  Future<void> stopService() async => _service.invoke('stopService');

  @override
  Future<bool> isRunning() => _service.isRunning();
}
