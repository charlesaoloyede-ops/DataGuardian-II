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
            val prefs = MonitorPrefs(ctx)
            val t = prefs.readThresholds()
            val now = System.currentTimeMillis()
            val dayKey = DAY_FMT.format(now)
            val notifier = MonitorNotifier(ctx)

            // ── Out-of-app update push (R1) ─────────────────────────────────
            // Runs before the usage-access gate: it needs neither the permission
            // nor live stats, so a user who granted notifications but not usage
            // access still gets update prompts. Gated only on notifications.
            if (t.notificationsEnabled) maybeCheckAppUpdate(ctx, prefs, notifier, dayKey)

            if (!UsageAccess.isGranted(ctx)) return Result.success()
            if (!t.notificationsEnabled) return Result.success()

            val todayStart = startOfToday()

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

            // ── Conversion nudges: budget / limits not yet set ──────────────
            maybeSendNudges(prefs, notifier, now, t)

            // ── Data bundle: exhaustion risk (R2) and top-up nudge (R3) ──────
            maybeCheckBundle(ctx, prefs, notifier, now, todayStart)

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

    /**
     * Fires the conversion nudges — one prompting the user to set a per-app data
     * budget, one to set daily/weekly/background limits — at most once every
     * [NUDGE_INTERVAL_MS], and only while the user hasn't converted. The first
     * encounter just seeds the timer, so a fresh install isn't nudged until the
     * interval has elapsed. Gated on notifications being enabled (checked by the
     * caller).
     */
    private fun maybeSendNudges(
        prefs: MonitorPrefs,
        notifier: MonitorNotifier,
        now: Long,
        t: MonitorPrefs.Thresholds,
    ) {
        if (!prefs.hasAnyAppBudget() && dueForNudge(prefs, NUDGE_BUDGET, now)) {
            notifier.show(
                MonitorNotifier.ID_NUDGE_BUDGET,
                NUDGE_BUDGET,
                "Set an app data budget",
                "Tap any app in Data Guardian to set a data budget and get alerted before it overspends.",
            )
            prefs.setNudgeLast(NUDGE_BUDGET, now)
        }

        // Nudge until all three limits are configured (daily, weekly, background).
        val allLimitsSet =
            t.dailyBytes != null && t.weeklyBytes != null && t.backgroundBytes != null
        if (!allLimitsSet && dueForNudge(prefs, NUDGE_LIMITS, now)) {
            notifier.show(
                MonitorNotifier.ID_NUDGE_LIMITS,
                NUDGE_LIMITS,
                "Set your data limits",
                "Set daily, weekly, and background data limits so Data Guardian can warn you before you go over.",
            )
            prefs.setNudgeLast(NUDGE_LIMITS, now)
        }
    }

    /**
     * R1: checks for a published sideload update and posts a push when the
     * installed build is behind — so users on a stale version get prompted even
     * while the app is closed. De-duped to at most once per day for the same
     * pending version (a newer version re-notifies immediately). Tapping opens
     * the app, which shows the existing in-app update sheet.
     */
    private fun maybeCheckAppUpdate(
        ctx: Context,
        prefs: MonitorPrefs,
        notifier: MonitorNotifier,
        dayKey: String,
    ) {
        val available = UpdateCheck.check(ctx) ?: return
        if (prefs.appUpdateNotifiedVersion() == available.versionCode &&
            prefs.appUpdateNotifiedDay() == dayKey
        ) {
            return
        }
        val vn = if (available.versionName.isNotEmpty()) " (v${available.versionName})" else ""
        notifier.show(
            MonitorNotifier.ID_APP_UPDATE,
            APP_UPDATE,
            "Update available",
            "A new version of Data Guardian$vn is ready. Tap to update.",
        )
        prefs.setAppUpdateNotified(available.versionCode, dayKey)
    }

    /**
     * Evaluates the monitored data bundle against live consumption and fires the
     * two distinct bundle alerts:
     *   • R2 exhaustion risk — projected run-out is before expiry. Fires once,
     *     stays silent while at risk, and re-arms only after ≥24h back on track.
     *   • R3 top-up nudge — remaining balance is down to ~3 days of runway
     *     (≤ 3× the daily average). Fires once per crossing; re-arms when the
     *     balance climbs back above the threshold (e.g. after a top-up).
     * Both are independent (either, both, or neither may fire) and use
     * device-level mobile bytes, so hotspot/tethered traffic counts — exactly
     * what the carrier bills against the bundle.
     */
    private fun maybeCheckBundle(
        ctx: Context,
        prefs: MonitorPrefs,
        notifier: MonitorNotifier,
        now: Long,
        todayStart: Long,
    ) {
        val b = prefs.readBundle() ?: return
        if (now >= b.expiryMs) return // bundle period is over — nothing to monitor

        val avg = deviceDailyAverage(ctx, todayStart) ?: return // need a baseline first
        val consumed = NetworkStatsQuery.mobileDeviceTotal(ctx, b.anchorAtMs, now)
        val remaining = (b.anchorBalanceBytes - consumed).coerceAtLeast(0L)
        val runwayDays = remaining / avg
        val daysToExpiry = (b.expiryMs - now).toDouble() / DAY_MS

        // ── R2: on pace to run out before the bundle expires ────────────────
        val atRisk = remaining > 0 && runwayDays < daysToExpiry
        if (atRisk) {
            if (!prefs.bundleAlertFired(RISK, b.anchorAtMs)) {
                val early = Math.round(daysToExpiry - runwayDays).coerceAtLeast(1L)
                val msg = "At your current pace you'll finish your data bundle about " +
                    "${plural(early, "day")} before it expires. Ease up or top up."
                notifier.show(MonitorNotifier.ID_BUNDLE_RISK, RISK, "Bundle running out early", msg)
                prefs.setBundleAlertFired(RISK, b.anchorAtMs, true)
                prefs.enqueuePendingAlert(RISK, msg, now)
                MonitorAnalytics.logAlertFired(ctx, RISK)
            }
            prefs.setBundleRiskClearSince(b.anchorAtMs, 0L) // reset the clear timer
        } else if (prefs.bundleAlertFired(RISK, b.anchorAtMs)) {
            // Back on track: re-arm only after a full day of sustained recovery.
            val since = prefs.bundleRiskClearSince(b.anchorAtMs)
            if (since == 0L) {
                prefs.setBundleRiskClearSince(b.anchorAtMs, now)
            } else if (now - since >= DAY_MS) {
                prefs.setBundleAlertFired(RISK, b.anchorAtMs, false)
            }
        }

        // ── R3: down to roughly 3 days of runway ────────────────────────────
        val lowRunway = remaining <= 3 * avg
        if (lowRunway) {
            if (!prefs.bundleAlertFired(TOPUP, b.anchorAtMs)) {
                val days = Math.round(runwayDays).coerceAtLeast(0L)
                val msg = "You have about ${fmt(remaining)} left — roughly " +
                    "${plural(days, "day")} at your usual pace. Tap to top up."
                notifier.show(MonitorNotifier.ID_BUNDLE_TOPUP, TOPUP, "About 3 days of data left", msg)
                prefs.setBundleAlertFired(TOPUP, b.anchorAtMs, true)
                prefs.enqueuePendingAlert(TOPUP, msg, now)
                MonitorAnalytics.logAlertFired(ctx, TOPUP)
            }
        } else if (prefs.bundleAlertFired(TOPUP, b.anchorAtMs)) {
            prefs.setBundleAlertFired(TOPUP, b.anchorAtMs, false) // climbed back above 3×
        }
    }

    /**
     * Average daily device-level mobile bytes over the previous up-to-7
     * completed days (hotspot/tethering included). Null when fewer than
     * [MIN_BASELINE_DAYS] of those days have usage — no reliable pace yet.
     */
    private fun deviceDailyAverage(ctx: Context, todayStart: Long): Double? {
        var sum = 0L
        var daysWithUsage = 0
        for (i in 1..7) {
            val dayStart = todayStart - i * DAY_MS
            val dayEnd = dayStart + DAY_MS - 1
            val bytes = NetworkStatsQuery.mobileDeviceTotal(ctx, dayStart, dayEnd)
            if (bytes > 0) {
                sum += bytes
                daysWithUsage++
            }
        }
        if (daysWithUsage < MIN_BASELINE_DAYS) return null
        return sum.toDouble() / daysWithUsage
    }

    private fun plural(n: Long, unit: String): String =
        if (n == 1L) "1 $unit" else "$n ${unit}s"

    /** Due when the interval has elapsed. First call seeds the timer (no nudge),
     *  so a brand-new user gets a grace period rather than an instant prompt. */
    private fun dueForNudge(prefs: MonitorPrefs, kind: String, now: Long): Boolean {
        val last = prefs.nudgeLastMs(kind)
        if (last == 0L) {
            prefs.setNudgeLast(kind, now)
            return false
        }
        return now - last >= NUDGE_INTERVAL_MS
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
        private const val NUDGE_BUDGET = "nudge_budget"
        private const val NUDGE_LIMITS = "nudge_limits"
        private const val RISK = "bundle_risk"
        private const val TOPUP = "bundle_topup"
        private const val APP_UPDATE = "app_update"
        private const val MIN_BASELINE_DAYS = 3
        private const val DAY_MS = 24L * 60 * 60 * 1000
        private const val NUDGE_INTERVAL_MS = 3L * 24 * 60 * 60 * 1000 // every 3 days
        private val DAY_FMT = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    }
}
