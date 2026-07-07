package com.dataguardian.app

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.dataguardian.app.channels.MonitorChannel
import com.dataguardian.app.channels.NetworkStatsChannel
import com.dataguardian.app.channels.UsageStatsChannel
import com.dataguardian.app.monitor.UsageAccess
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NetworkStatsChannel(this).register(flutterEngine)
        UsageStatsChannel(this).register(flutterEngine)
        MonitorChannel(this).register(flutterEngine)
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
