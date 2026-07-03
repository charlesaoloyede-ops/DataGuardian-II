package com.example.dataguardian

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.os.Build
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** Shared helpers for reading per-app mobile data usage, used by both the UI and the background worker. */
object NetworkUsage {
    private val dayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    fun startOfMonthMillis(): Long = Calendar.getInstance().run {
        set(Calendar.DAY_OF_MONTH, 1)
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
        timeInMillis
    }

    fun startOfTodayMillis(): Long = Calendar.getInstance().run {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
        timeInMillis
    }

    fun dayKey(millis: Long): String = dayFormat.format(Date(millis))

    /** Total mobile bytes per uid between [start] and [end]. */
    fun queryBytesByUid(context: Context, start: Long, end: Long): Map<Int, Long> {
        val totals = mutableMapOf<Int, Long>()
        forEachBucket(context, start, end) { uid, _, bytes ->
            totals[uid] = (totals[uid] ?: 0L) + bytes
        }
        return totals
    }

    /** Mobile bytes per uid, broken down by calendar day, between [start] and [end]. */
    fun queryDailyBytesByUid(context: Context, start: Long, end: Long): Map<Int, MutableMap<String, Long>> {
        val totals = mutableMapOf<Int, MutableMap<String, Long>>()
        forEachBucket(context, start, end) { uid, bucketStart, bytes ->
            val byDay = totals.getOrPut(uid) { mutableMapOf() }
            val key = dayKey(bucketStart)
            byDay[key] = (byDay[key] ?: 0L) + bytes
        }
        return totals
    }

    private inline fun forEachBucket(
        context: Context,
        start: Long,
        end: Long,
        onBucket: (uid: Int, bucketStart: Long, bytes: Long) -> Unit,
    ) {
        val manager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        @Suppress("DEPRECATION")
        val stats = manager.querySummary(ConnectivityManager.TYPE_MOBILE, null, start, end)
        stats.use { networkStats ->
            val bucket = NetworkStats.Bucket()
            while (networkStats.hasNextBucket()) {
                networkStats.getNextBucket(bucket)
                onBucket(bucket.uid, bucket.startTimeStamp, bucket.rxBytes + bucket.txBytes)
            }
        }
    }

    data class InstalledApp(val uid: Int, val label: String, val packageName: String)

    @Suppress("DEPRECATION")
    fun installedApps(context: Context): List<InstalledApp> {
        val packageManager = context.packageManager
        val applications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledApplications(
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong())
            )
        } else {
            packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        }
        return applications
            .filter { it.enabled && (it.flags and ApplicationInfo.FLAG_INSTALLED) != 0 }
            .map { app ->
                InstalledApp(
                    uid = app.uid,
                    label = packageManager.getApplicationLabel(app).toString(),
                    packageName = app.packageName,
                )
            }
    }
}
