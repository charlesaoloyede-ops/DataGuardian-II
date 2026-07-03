package com.dataguardian.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class DataGuardianApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        // Background service scheduling added in Phase 6
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        nm.createNotificationChannel(
            NotificationChannel(
                "data_guardian_alerts",
                "Data Alerts",
                NotificationManager.IMPORTANCE_DEFAULT,
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
