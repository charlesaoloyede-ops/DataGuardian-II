package com.example.dataguardian

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class DataGuardianApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        scheduleUsageCheck(this)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            UsageCheckWorker.CHANNEL_ID,
            "Data usage alerts",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Alerts when an app nears its data budget or shows unusual usage."
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        fun scheduleUsageCheck(context: Application) {
            val request = PeriodicWorkRequestBuilder<UsageCheckWorker>(15, TimeUnit.MINUTES).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UsageCheckWorker.UNIQUE_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }
}
