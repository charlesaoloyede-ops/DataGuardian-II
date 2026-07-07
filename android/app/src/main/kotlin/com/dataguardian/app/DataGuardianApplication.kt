package com.dataguardian.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.FlutterInjector

class DataGuardianApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Pre-initialise the Flutter loader so the background service engine
        // can start without a foreground Activity.
        FlutterInjector.instance().flutterLoader().startInitialization(this)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        nm.createNotificationChannel(
            NotificationChannel(
                "data_guardian_alerts",
                "Data Alerts",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Budget and spike usage alerts" }
        )
        nm.createNotificationChannel(
            NotificationChannel(
                "data_guardian_monitor",
                "Background Monitor",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { description = "Persistent monitoring notification" }
        )
    }
}
