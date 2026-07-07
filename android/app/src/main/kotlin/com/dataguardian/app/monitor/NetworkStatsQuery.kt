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
 * Unlike the per-app query in NetworkStatsChannel, these return device-level
 * totals which are cheaper and sufficient for threshold/spike evaluation and
 * the 7-day chart.
 */
object NetworkStatsQuery {

    data class DayTotal(val startMs: Long, val mobileBytes: Long, val wifiBytes: Long)

    /** Total mobile bytes (rx+tx) across the device for [startMs]..[endMs]. */
    fun mobileTotal(context: Context, startMs: Long, endMs: Long): Long =
        deviceTotal(context, ConnectivityManager.TYPE_MOBILE, startMs, endMs)

    /** Total Wi-Fi bytes (rx+tx) across the device for [startMs]..[endMs]. */
    fun wifiTotal(context: Context, startMs: Long, endMs: Long): Long =
        deviceTotal(context, ConnectivityManager.TYPE_WIFI, startMs, endMs)

    /**
     * Mobile bytes attributed to background state (STATE_DEFAULT) for the window.
     * Requires per-uid iteration since device-level summaries don't split state.
     */
    fun mobileBackgroundTotal(context: Context, startMs: Long, endMs: Long): Long {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val stats = nsm.querySummary(ConnectivityManager.TYPE_MOBILE, null, startMs, endMs)
        val bucket = NetworkStats.Bucket()
        var background = 0L
        while (stats.hasNextBucket()) {
            stats.getNextBucket(bucket)
            if (bucket.state == NetworkStats.Bucket.STATE_DEFAULT) {
                background += bucket.rxBytes + bucket.txBytes
            }
        }
        stats.close()
        return background
    }

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

    private fun deviceTotal(context: Context, transport: Int, startMs: Long, endMs: Long): Long {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val bucket = nsm.querySummaryForDevice(transport, null, startMs, endMs)
        return bucket.rxBytes + bucket.txBytes
    }

    private const val DAY_MS = 24L * 60 * 60 * 1000
}
