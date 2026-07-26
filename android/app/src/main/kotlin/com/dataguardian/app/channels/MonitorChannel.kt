package com.dataguardian.app.channels

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.dataguardian.app.MainActivity
import com.dataguardian.app.monitor.MonitorNotifier
import com.dataguardian.app.monitor.MonitorScheduler
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "com.dataguardian/monitor"

/**
 * Controls the native background monitor (WorkManager) and exposes
 * battery-optimization helpers so the Dart side can ask the user to exempt the
 * app — the main lever for keeping background checks running on aggressive OEMs.
 */
class MonitorChannel(private val activity: MainActivity) {

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMonitoring" -> {
                        MonitorScheduler.start(activity.applicationContext)
                        // Show the persistent status entry right away; the worker
                        // refreshes it with real totals on its next run.
                        MonitorNotifier(activity.applicationContext)
                            .showOngoingStatus("Monitoring your data usage…")
                        result.success(true)
                    }
                    "stopMonitoring" -> {
                        MonitorScheduler.stop(activity.applicationContext)
                        MonitorNotifier(activity.applicationContext).cancelOngoing()
                        result.success(true)
                    }
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations(activity))
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations(activity)
                        result.success(null)
                    }
                    "areNotificationsEnabled" ->
                        result.success(
                            NotificationManagerCompat.from(activity).areNotificationsEnabled()
                        )
                    "openNotificationSettings" -> {
                        openNotificationSettings(activity)
                        result.success(null)
                    }
                    "consumeLaunchRoute" -> result.success(activity.consumeLaunchRoute())
                    "sendTestNudge" -> {
                        MonitorNotifier(activity.applicationContext).show(
                            MonitorNotifier.ID_NUDGE_BUDGET,
                            "nudge_budget",
                            "Set an app data budget",
                            "Tap here, then tap any app to set a data budget and get alerted before it overspends.",
                        )
                        result.success(true)
                    }
                    "sendTestNotification" -> {
                        MonitorNotifier(activity.applicationContext).show(
                            MonitorNotifier.ID_TEST,
                            "test",
                            "Test notification",
                            "Push notifications are working. You'll get alerts here.",
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openNotificationSettings(context: Context) {
        try {
            context.startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            )
        } catch (_: Exception) {
            try {
                context.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .setData(Uri.parse("package:${context.packageName}"))
                )
            } catch (_: Exception) {
                // No settings UI available.
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    @Suppress("BatteryLife")
    private fun requestIgnoreBatteryOptimizations(context: Context) {
        // ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS shows the system dialog
        // directly. If unavailable, fall back to the settings list.
        try {
            context.startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:${context.packageName}"))
            )
        } catch (_: Exception) {
            try {
                context.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
                // No battery-optimization UI on this device — nothing to do.
            }
        }
    }
}
