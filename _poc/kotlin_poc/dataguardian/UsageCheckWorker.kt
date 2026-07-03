package com.example.dataguardian

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Runs periodically in the background (independent of the app's UI) to check each app with a
 * configured data budget against 80/90/100% thresholds, and to flag days where an app's usage is
 * far outside its recent daily pattern.
 */
class UsageCheckWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val monthFormat = SimpleDateFormat("yyyy-MM", Locale.US)

    override fun doWork(): Result {
        val context = applicationContext
        val budgets = UsageBudgetStore(context).allBudgets()
        val apps = NetworkUsage.installedApps(context).associateBy { it.uid }
        val now = System.currentTimeMillis()
        val state = AlertStateStore(context)

        val monthlyBytesByUid = NetworkUsage.queryBytesByUid(context, NetworkUsage.startOfMonthMillis(), now)
        checkBudgets(context, apps, monthlyBytesByUid, budgets, state)

        val dailyBytesByUid = NetworkUsage.queryDailyBytesByUid(
            context,
            NetworkUsage.startOfTodayMillis() - DAYS_OF_HISTORY * DAY_MILLIS,
            now
        )
        checkSpikes(context, apps, dailyBytesByUid, now, state)

        return Result.success()
    }

    private fun checkBudgets(
        context: Context,
        apps: Map<Int, NetworkUsage.InstalledApp>,
        monthlyBytesByUid: Map<Int, Long>,
        budgets: Map<String, Long>,
        state: AlertStateStore,
    ) {
        val monthKey = monthFormat.format(java.util.Date())
        for ((packageName, budget) in budgets) {
            if (budget <= 0) continue
            val app = apps.values.find { it.packageName == packageName } ?: continue
            val used = monthlyBytesByUid[app.uid] ?: 0L
            val percent = used * 100.0 / budget
            val notified = state.notifiedThresholds(packageName, monthKey)
            for (threshold in intArrayOf(100, 90, 80)) {
                if (percent >= threshold && threshold !in notified) {
                    state.markThresholdNotified(packageName, monthKey, threshold)
                    notify(
                        context,
                        id = (packageName + "_budget_$threshold").hashCode(),
                        title = "${app.label}: $threshold% of data budget used",
                        body = "${formatBytes(used)} of ${formatBytes(budget)} used this month.",
                    )
                    break
                }
            }
        }
    }

    private fun checkSpikes(
        context: Context,
        apps: Map<Int, NetworkUsage.InstalledApp>,
        dailyBytesByUid: Map<Int, Map<String, Long>>,
        now: Long,
        state: AlertStateStore,
    ) {
        val todayKey = NetworkUsage.dayKey(now)
        val fractionOfDayElapsed = ((now - NetworkUsage.startOfTodayMillis()).toDouble() / DAY_MILLIS)
            .coerceIn(0.05, 1.0)

        for ((uid, byDay) in dailyBytesByUid) {
            val app = apps[uid] ?: continue
            val todayBytes = byDay[todayKey] ?: 0L
            val pastDays = byDay.filterKeys { it != todayKey }.values
            if (pastDays.size < MIN_HISTORY_DAYS) continue

            val baseline = pastDays.average()
            if (baseline < SPIKE_MIN_BASELINE_BYTES) continue

            val expectedSoFar = baseline * fractionOfDayElapsed
            val isSpike = todayBytes > SPIKE_MIN_ABSOLUTE_BYTES && todayBytes > expectedSoFar * SPIKE_MULTIPLIER
            if (!isSpike) continue

            if (state.spikeAlreadyNotified(app.packageName, todayKey)) continue
            state.markSpikeNotified(app.packageName, todayKey)
            notify(
                context,
                id = (app.packageName + "_spike").hashCode(),
                title = "${app.label}: unusual data usage today",
                body = "${formatBytes(todayBytes)} used today, well above its typical pace.",
            )
        }
    }

    private fun notify(context: Context, id: Int, title: String, body: String) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent()
        val pendingIntent = PendingIntent.getActivity(
            context,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            // Notification permission not granted; nothing to do until the user grants it.
        }
    }

    private fun formatBytes(bytes: Long): String {
        if (bytes < 1000) return "$bytes B"
        val units = listOf("KB", "MB", "GB", "TB")
        var value = bytes / 1000.0
        var unit = 0
        while (value >= 1000 && unit < units.size - 1) {
            value /= 1000
            unit++
        }
        return "%.1f %s".format(value, units[unit])
    }

    companion object {
        const val CHANNEL_ID = "data_guardian_usage_alerts"
        const val UNIQUE_WORK_NAME = "usage_check"
        private const val DAY_MILLIS = 24L * 60 * 60 * 1000
        private const val DAYS_OF_HISTORY = 8L
        private const val MIN_HISTORY_DAYS = 3
        private const val SPIKE_MIN_BASELINE_BYTES = 5_000_000L
        private const val SPIKE_MIN_ABSOLUTE_BYTES = 10_000_000L
        private const val SPIKE_MULTIPLIER = 2.5
    }
}
