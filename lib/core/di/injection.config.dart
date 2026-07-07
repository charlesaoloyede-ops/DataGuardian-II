// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/alerts/data/alert_repository_impl.dart' as _i38;
import '../../features/alerts/domain/i_alert_repository.dart' as _i646;
import '../../features/alerts/domain/use_cases/check_budget_use_case.dart'
    as _i819;
import '../../features/alerts/domain/use_cases/check_spike_use_case.dart'
    as _i1035;
import '../../features/alerts/domain/use_cases/check_threshold_use_case.dart'
    as _i615;
import '../../features/alerts/domain/use_cases/get_alerts_use_case.dart'
    as _i109;
import '../../features/alerts/domain/use_cases/mark_all_read_use_case.dart'
    as _i380;
import '../../features/alerts/domain/use_cases/save_alert_use_case.dart'
    as _i680;
import '../../features/app_usage/data/app_usage_repository_impl.dart' as _i157;
import '../../features/app_usage/data/daily_usage_repository_impl.dart'
    as _i734;
import '../../features/app_usage/domain/i_daily_usage_repository.dart' as _i656;
import '../../features/app_usage/domain/i_network_stats_repository.dart'
    as _i964;
import '../../features/app_usage/domain/use_cases/get_app_usage_use_case.dart'
    as _i554;
import '../../features/app_usage/domain/use_cases/sync_daily_usage_use_case.dart'
    as _i877;
import '../../features/dashboard/domain/use_cases/get_dashboard_summary_use_case.dart'
    as _i739;
import '../../features/onboarding/data/onboarding_repository_impl.dart'
    as _i624;
import '../../features/onboarding/domain/i_onboarding_repository.dart' as _i737;
import '../../features/onboarding/domain/use_cases/complete_onboarding_use_case.dart'
    as _i799;
import '../../services/background/background_service_manager.dart' as _i697;
import '../../services/background/i_background_service_manager.dart' as _i877;
import '../../services/notification/i_notification_service.dart' as _i800;
import '../../services/notification/notification_service_impl.dart' as _i68;
import '../../services/storage/hive_service.dart' as _i13;
import '../../services/storage/shared_prefs_service.dart' as _i86;
import '../analytics/i_analytics_service.dart' as _i26;
import '../analytics/noop_analytics_service.dart' as _i978;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i13.HiveService>(() => _i13.HiveService());
    gh.lazySingletonAsync<_i86.SharedPrefsService>(
        () => _i86.SharedPrefsService.create());
    gh.lazySingleton<_i800.INotificationService>(
        () => _i68.NotificationServiceImpl());
    gh.lazySingleton<_i877.IBackgroundServiceManager>(
        () => _i697.BackgroundServiceManager());
    gh.factoryAsync<_i819.CheckBudgetUseCase>(() async =>
        _i819.CheckBudgetUseCase(await getAsync<_i86.SharedPrefsService>()));
    gh.lazySingletonAsync<_i737.IOnboardingRepository>(() async =>
        _i624.OnboardingRepositoryImpl(
            await getAsync<_i86.SharedPrefsService>()));
    gh.lazySingleton<_i26.IAnalyticsService>(
        () => _i978.NoOpAnalyticsService());
    gh.lazySingleton<_i656.IDailyUsageRepository>(
        () => _i734.DailyUsageRepositoryImpl(gh<_i13.HiveService>()));
    gh.factoryAsync<_i799.CompleteOnboardingUseCase>(() async =>
        _i799.CompleteOnboardingUseCase(
            await getAsync<_i737.IOnboardingRepository>()));
    gh.lazySingleton<_i646.IAlertRepository>(
        () => _i38.AlertRepositoryImpl(gh<_i13.HiveService>()));
    gh.factoryAsync<_i1035.CheckSpikeUseCase>(
        () async => _i1035.CheckSpikeUseCase(
              gh<_i656.IDailyUsageRepository>(),
              await getAsync<_i86.SharedPrefsService>(),
            ));
    gh.lazySingleton<_i964.INetworkStatsRepository>(
        () => _i157.AppUsageRepositoryImpl(gh<_i26.IAnalyticsService>()));
    gh.factory<_i877.SyncDailyUsageUseCase>(() => _i877.SyncDailyUsageUseCase(
          gh<_i964.INetworkStatsRepository>(),
          gh<_i656.IDailyUsageRepository>(),
        ));
    gh.factory<_i380.MarkAllReadUseCase>(
        () => _i380.MarkAllReadUseCase(gh<_i646.IAlertRepository>()));
    gh.factory<_i680.SaveAlertUseCase>(
        () => _i680.SaveAlertUseCase(gh<_i646.IAlertRepository>()));
    gh.factory<_i109.GetAlertsUseCase>(
        () => _i109.GetAlertsUseCase(gh<_i646.IAlertRepository>()));
    gh.factoryAsync<_i615.CheckThresholdUseCase>(
        () async => _i615.CheckThresholdUseCase(
              gh<_i964.INetworkStatsRepository>(),
              await getAsync<_i86.SharedPrefsService>(),
            ));
    gh.factory<_i554.GetAppUsageUseCase>(
        () => _i554.GetAppUsageUseCase(gh<_i964.INetworkStatsRepository>()));
    gh.factoryAsync<_i739.GetDashboardSummaryUseCase>(
        () async => _i739.GetDashboardSummaryUseCase(
              gh<_i964.INetworkStatsRepository>(),
              gh<_i656.IDailyUsageRepository>(),
              await getAsync<_i86.SharedPrefsService>(),
              gh<_i877.SyncDailyUsageUseCase>(),
            ));
    return this;
  }
}
