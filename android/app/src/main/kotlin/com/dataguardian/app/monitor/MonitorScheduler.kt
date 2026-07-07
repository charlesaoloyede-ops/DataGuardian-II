package com.dataguardian.app.monitor

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Schedules the [UsageMonitorWorker] as unique periodic work. WorkManager
 * persists the job across process death and reboots, so monitoring survives
 * the app being killed — the core reason for moving evaluation off the Dart
 * isolate.
 */
object MonitorScheduler {

    private const val WORK_NAME = "data_guardian_usage_monitor"
    private const val INTERVAL_MINUTES = 15L // WorkManager's minimum periodic interval

    fun start(context: Context) {
        val request = PeriodicWorkRequestBuilder<UsageMonitorWorker>(
            INTERVAL_MINUTES, TimeUnit.MINUTES,
        ).build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            // KEEP: don't reset the schedule if already running (e.g. every app open).
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun stop(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }
}
