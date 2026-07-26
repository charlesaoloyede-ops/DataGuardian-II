package com.dataguardian.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import com.dataguardian.app.channels.AppUpdateChannel
import com.dataguardian.app.channels.MonitorChannel
import com.dataguardian.app.channels.NetworkStatsChannel
import com.dataguardian.app.channels.UsageStatsChannel
import com.dataguardian.app.monitor.MonitorAnalytics
import com.dataguardian.app.monitor.MonitorNotifier
import com.dataguardian.app.monitor.UsageAccess
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    /** Route the app should navigate to on launch, set when opened from a
     *  conversion-nudge notification. Consumed once by the Dart side. */
    private var pendingRoute: String? = null

    fun consumeLaunchRoute(): String? {
        val r = pendingRoute
        pendingRoute = null
        return r
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NetworkStatsChannel(this).register(flutterEngine)
        UsageStatsChannel(this).register(flutterEngine)
        MonitorChannel(this).register(flutterEngine)
        AppUpdateChannel(this).register(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logNotificationOpenIfPresent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        logNotificationOpenIfPresent(intent)
    }

    /** Records a notification-tap conversion when the app is opened from one. */
    private fun logNotificationOpenIfPresent(intent: Intent?) {
        if (intent?.getBooleanExtra(MonitorNotifier.EXTRA_FROM_NOTIFICATION, false) != true) return
        val type = intent.getStringExtra(MonitorNotifier.EXTRA_NOTIFICATION_TYPE) ?: "unknown"
        MonitorAnalytics.logNotificationOpened(this, type)
        // Deep-link conversion nudges straight to where the user can act.
        pendingRoute = when (type) {
            "nudge_budget" -> "/app-usage"
            "nudge_limits" -> "/alerts"
            else -> pendingRoute
        }
        // Clear so an activity recreate (e.g. rotation) doesn't double-count.
        intent.removeExtra(MonitorNotifier.EXTRA_FROM_NOTIFICATION)
        intent.removeExtra(MonitorNotifier.EXTRA_NOTIFICATION_TYPE)
    }

    /** Used by UsageStatsChannel to open the system settings screen. */
    fun openUsageAccessSettings() {
        val direct = Intent(
            Settings.ACTION_USAGE_ACCESS_SETTINGS,
            Uri.parse("package:$packageName")
        )
        try {
            startActivity(direct)
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    /** Checks whether usage-stats / network-stats access has been granted. */
    fun isUsageAccessGranted(): Boolean = UsageAccess.isGranted(this)

    fun openAppDetailsSettings() {
        startActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName")
            )
        )
    }
}
