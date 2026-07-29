package com.dataguardian.app.monitor

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import java.util.Calendar

/**
 * Context-based NetworkStatsManager queries shared by the foreground chart
 * (via NetworkStatsChannel) and the background [UsageMonitorWorker].
 *
 * These sum per-UID summary buckets (uid >= 0) exactly like
 * NetworkStatsChannel's per-app query, so every number in the app — the App
 * Usage list, the billing-cycle card, the 7-day chart, and the alert worker —
 * comes from the same source and agrees. (Device-level `querySummaryForDevice`
 * is deliberately avoided: it can include traffic not attributed to any app,
 * so it disagrees with the per-app totals shown elsewhere.)
 */
object NetworkStatsQuery {

    data class DayTotal(val startMs: Long, val mobileBytes: Long, val wifiBytes: Long)

    /** Total mobile bytes (rx+tx) across all apps for [startMs]..[endMs]. */
    fun mobileTotal(context: Context, startMs: Long, endMs: Long): Long =
        sumPerUid(context, ConnectivityManager.TYPE_MOBILE, startMs, endMs, backgroundOnly = false)

    /**
     * Device-level total mobile bytes (rx+tx) for the window — the whole-SIM
     * figure the carrier bills against a data bundle. Unlike [mobileTotal] (a
     * per-UID sum), this counts traffic that belongs to no app UID: hotspot /
     * tethering (attributed to UID_TETHERING = -5, which [sumPerUid] drops),
     * plus VPN and system traffic. A phone sharing its data over hotspot still
     * burns the bundle, so bundle monitoring MUST use this, not the per-app sum.
     *
     * subscriberId is null: since Android 11 the IMSI isn't available to normal
     * apps, and null returns the aggregate across SIMs — which is what we want.
     * Falls back to the per-UID sum if the OEM/platform rejects the device query
     * (still better than zero; only misses tethering).
     */
    fun mobileDeviceTotal(context: Context, startMs: Long, endMs: Long): Long {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        return try {
            val bucket = nsm.querySummaryForDevice(
                ConnectivityManager.TYPE_MOBILE, null, startMs, endMs,
            )
            (bucket?.rxBytes ?: 0L) + (bucket?.txBytes ?: 0L)
        } catch (_: Exception) {
            mobileTotal(context, startMs, endMs)
        }
    }

    /** Total Wi-Fi bytes (rx+tx) across all apps for [startMs]..[endMs]. */
    fun wifiTotal(context: Context, startMs: Long, endMs: Long): Long =
        sumPerUid(context, ConnectivityManager.TYPE_WIFI, startMs, endMs, backgroundOnly = false)

    /** Mobile bytes attributed to background state (STATE_DEFAULT) for the window. */
    fun mobileBackgroundTotal(context: Context, startMs: Long, endMs: Long): Long =
        sumPerUid(context, ConnectivityManager.TYPE_MOBILE, startMs, endMs, backgroundOnly = true)

    /**
     * One [DayTotal] per calendar day from the day containing [startMs] through
     * the day containing [endMs], inclusive. Days with no usage report zero.
     */
    fun dailyTotals(context: Context, startMs: Long, endMs: Long): List<DayTotal> {
        val cal = Calendar.getInstance().apply {
            timeInMillis = startMs
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val out = mutableListOf<DayTotal>()
        while (cal.timeInMillis <= endMs) {
            val dayStart = cal.timeInMillis
            val nextDay = dayStart + DAY_MS
            val dayEnd = (nextDay - 1).coerceAtMost(endMs)
            out += DayTotal(
                startMs = dayStart,
                mobileBytes = mobileTotal(context, dayStart, dayEnd),
                wifiBytes = wifiTotal(context, dayStart, dayEnd),
            )
            cal.timeInMillis = nextDay
        }
        return out
    }

    /**
     * Sums rx+tx over every summary bucket for [transport] with a real app UID
     * (uid >= 0), matching NetworkStatsChannel.accumulateTransport. When
     * [backgroundOnly] is set, only STATE_DEFAULT (background) buckets count.
     */
    private fun sumPerUid(
        context: Context,
        transport: Int,
        startMs: Long,
        endMs: Long,
        backgroundOnly: Boolean,
    ): Long {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val stats = nsm.querySummary(transport, null, startMs, endMs)
        val bucket = NetworkStats.Bucket()
        var total = 0L
        while (stats.hasNextBucket()) {
            stats.getNextBucket(bucket)
            if (bucket.uid < 0) continue
            if (backgroundOnly && bucket.state != NetworkStats.Bucket.STATE_DEFAULT) continue
            total += bucket.rxBytes + bucket.txBytes
        }
        stats.close()
        return total
    }

    private const val DAY_MS = 24L * 60 * 60 * 1000
}
