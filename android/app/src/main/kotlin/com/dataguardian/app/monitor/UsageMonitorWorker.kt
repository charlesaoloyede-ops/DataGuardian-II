package com.dataguardian.app.monitor

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Periodic background check (scheduled via WorkManager) that evaluates the
 * user's mobile-data thresholds against live NetworkStatsManager data and posts
 * notifications — independent of any Flutter isolate, so it keeps working when
 * the app is closed or killed.
 *
 * Mirrors the Dart use-cases (CheckThresholdUseCase / CheckSpikeUseCase): daily
 * and weekly totals, background-only usage, and a spike vs. the 7-day baseline.
 * Each alert fires at most once per calendar day (de-duped in [MonitorPrefs]).
 */
class UsageMonitorWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {
        val ctx = applicationContext
        try {
            if (!UsageAccess.isGranted(ctx)) return Result.success()

            val prefs = MonitorPrefs(ctx)
            val t = prefs.readThresholds()
            if (!t.notificationsEnabled) return Result.success()

            val now = System.currentTimeMillis()
            val dayKey = DAY_FMT.format(now)
            val todayStart = startOfToday()
            val notifier = MonitorNotifier(ctx)

            // ── Daily mobile threshold ──────────────────────────────────────
            val dailyMobile = NetworkStatsQuery.mobileTotal(ctx, todayStart, now)
            t.dailyBytes?.let { limit ->
                if (dailyMobile > limit && !prefs.hasFired(DAILY, dayKey)) {
                    val msg = "Daily mobile data limit reached: ${fmt(dailyMobile)} of ${fmt(limit)}"
                    notifier.show(MonitorNotifier.ID_DAILY, DAILY, "Daily Data Limit Reached", msg)
                    prefs.markFired(DAILY, dayKey)
                    prefs.enqueuePendingAlert("threshold", msg, now)
                    MonitorAnalytics.logAlertFired(ctx, DAILY)
                }
            }

            // ── Weekly mobile threshold (rolling last 7 days) ───────────────
            t.weeklyBytes?.let { limit ->
                if (!prefs.hasFired(WEEKLY, dayKey)) {
                    val weekStart = todayStart - 6 * DAY_MS
                    val weeklyMobile = NetworkStatsQuery.mobileTotal(ctx, weekStart, now)
                    if (weeklyMobile > limit) {
                        val msg = "Weekly mobile data limit reached: ${fmt(weeklyMobile)} of ${fmt(limit)}"
                        notifier.show(MonitorNotifier.ID_WEEKLY, WEEKLY, "Weekly Data Limit Reached", msg)
                        prefs.markFired(WEEKLY, dayKey)
                        prefs.enqueuePendingAlert("threshold", msg, now)
                        MonitorAnalytics.logAlertFired(ctx, WEEKLY)
                    }
                }
            }

            // ── Background-only mobile threshold ────────────────────────────
            t.backgroundBytes?.let { limit ->
                if (!prefs.hasFired(BACKGROUND, dayKey)) {
                    val bg = NetworkStatsQuery.mobileBackgroundTotal(ctx, todayStart, now)
                    if (bg > limit) {
                        val msg = "Background data limit exceeded: ${fmt(bg)} of ${fmt(limit)}"
                        notifier.show(MonitorNotifier.ID_BACKGROUND, BACKGROUND, "Background Data Alert", msg)
                        prefs.markFired(BACKGROUND, dayKey)
                        prefs.enqueuePendingAlert("background", msg, now)
                        MonitorAnalytics.logAlertFired(ctx, BACKGROUND)
                    }
                }
            }

            // ── Spike vs. 7-day baseline ────────────────────────────────────
            if (!prefs.hasFired(SPIKE, dayKey)) {
                val baseline = baselineAverage(ctx, todayStart)
                if (baseline != null && dailyMobile > baseline * t.spikeMultiplier) {
                    val mult = dailyMobile.toDouble() / baseline
                    val msg = "Data spike detected: ${fmt(dailyMobile)} today " +
                        "(${String.format(Locale.US, "%.1f", mult)}× your average daily use " +
                        "of ${fmt(baseline.toLong())})"
                    notifier.show(MonitorNotifier.ID_SPIKE, SPIKE, "Data Spike Detected", msg)
                    prefs.markFired(SPIKE, dayKey)
                    prefs.enqueuePendingAlert("spike", msg, now)
                    MonitorAnalytics.logAlertFired(ctx, SPIKE)
                }
            }

            // Refresh the persistent status notification with today's totals.
            val wifiToday = NetworkStatsQuery.wifiTotal(ctx, todayStart, now)
            notifier.showOngoingStatus(
                "Today: ${fmt(dailyMobile)} mobile · ${fmt(wifiToday)} Wi-Fi",
            )

            return Result.success()
        } catch (_: Exception) {
            // Never surface a hard failure — retry on the next periodic run.
            return Result.success()
        }
    }

    /**
     * Average daily mobile bytes over the previous up-to-7 completed days.
     * Returns null when fewer than [MIN_BASELINE_DAYS] of those days have any
     * usage, matching the Dart spike use-case's minimum-baseline guard.
     */
    private fun baselineAverage(ctx: Context, todayStart: Long): Double? {
        var sum = 0L
        var daysWithUsage = 0
        for (i in 1..7) {
            val dayStart = todayStart - i * DAY_MS
            val dayEnd = dayStart + DAY_MS - 1
            val bytes = NetworkStatsQuery.mobileTotal(ctx, dayStart, dayEnd)
            if (bytes > 0) {
                sum += bytes
                daysWithUsage++
            }
        }
        if (daysWithUsage < MIN_BASELINE_DAYS) return null
        return sum.toDouble() / daysWithUsage
    }

    private fun startOfToday(): Long = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    private fun fmt(bytes: Long): String {
        val mb = bytes / 1_000_000.0
        return if (mb >= 1000) String.format(Locale.US, "%.1f GB", mb / 1000)
        else String.format(Locale.US, "%.0f MB", mb)
    }

    companion object {
        private const val DAILY = "daily"
        private const val WEEKLY = "weekly"
        private const val BACKGROUND = "background"
        private const val SPIKE = "spike"
        private const val MIN_BASELINE_DAYS = 3
        private const val DAY_MS = 24L * 60 * 60 * 1000
        private val DAY_FMT = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    }
}
