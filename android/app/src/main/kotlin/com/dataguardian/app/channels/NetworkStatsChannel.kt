package com.dataguardian.app.channels

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import com.dataguardian.app.MainActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

private const val CHANNEL = "com.dataguardian/network_stats"

/**
 * Bridges Flutter to Android's [NetworkStatsManager] API.
 *
 * Per-app foreground/background bytes are split using [NetworkStats.Bucket.STATE_FOREGROUND]
 * vs [NetworkStats.Bucket.STATE_DEFAULT]. On devices where the driver does not split traffic
 * state (bucket.state == STATE_ALL), all bytes are counted as foreground to avoid under-counting.
 *
 * OEM restriction (MIUI, EMUI, ColorOS): [NetworkStatsManager.querySummary] may throw
 * [SecurityException] or return all-zero buckets even when permission is granted.
 * The Dart repository layer handles this by catching the error code and showing a banner.
 */
class NetworkStatsChannel(private val activity: MainActivity) {

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNetworkStats" -> handleGetNetworkStats(call.arguments, result)
                    "getNetworkStatsByUid" -> handleGetNetworkStatsByUid(call.arguments, result)
                    "getDailyTotals" -> handleGetDailyTotals(call.arguments, result)
                    else -> result.notImplemented()
                }
            }
    }

    // ── getDailyTotals ───────────────────────────────────────────────────────

    /**
     * Returns one entry per calendar day in the window with device-level mobile
     * and Wi-Fi totals. Backs the dashboard 7-day chart so it reads from the
     * same live NetworkStatsManager source as the App Usage screen.
     */
    private fun handleGetDailyTotals(rawArgs: Any?, result: MethodChannel.Result) {
        if (!activity.isUsageAccessGranted()) {
            result.error("USAGE_ACCESS_REQUIRED", "Grant usage access in Settings.", null)
            return
        }
        val args    = rawArgs as? Map<*, *>
        val startMs = (args?.get("startMs") as? Number)?.toLong() ?: defaultStartMs()
        val endMs   = (args?.get("endMs")   as? Number)?.toLong() ?: System.currentTimeMillis()

        executor.execute {
            try {
                val days = com.dataguardian.app.monitor.NetworkStatsQuery
                    .dailyTotals(activity, startMs, endMs)
                    .map {
                        mapOf(
                            "startMs"     to it.startMs,
                            "mobileBytes" to it.mobileBytes,
                            "wifiBytes"   to it.wifiBytes,
                        )
                    }
                mainHandler.post { result.success(days) }
            } catch (e: SecurityException) {
                mainHandler.post {
                    result.error("NETWORK_STATS_RESTRICTED", "Per-app data unavailable on this device.", e.message)
                }
            } catch (e: Exception) {
                mainHandler.post { result.error("NETWORK_STATS_FAILED", e.message, null) }
            }
        }
    }

    // ── getNetworkStats ──────────────────────────────────────────────────────

    private fun handleGetNetworkStats(rawArgs: Any?, result: MethodChannel.Result) {
        if (!activity.isUsageAccessGranted()) {
            result.error("USAGE_ACCESS_REQUIRED", "Grant usage access in Settings.", null)
            return
        }
        val args = rawArgs as? Map<*, *>
        val startMs = (args?.get("startMs") as? Number)?.toLong() ?: defaultStartMs()
        val endMs   = (args?.get("endMs")   as? Number)?.toLong() ?: System.currentTimeMillis()

        executor.execute {
            try {
                val stats = buildAppStatsList(startMs, endMs)
                mainHandler.post { result.success(stats) }
            } catch (e: SecurityException) {
                mainHandler.post {
                    result.error("NETWORK_STATS_RESTRICTED", "Per-app data unavailable on this device.", e.message)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("NETWORK_STATS_FAILED", e.message, null)
                }
            }
        }
    }

    // ── getNetworkStatsByUid ─────────────────────────────────────────────────

    private fun handleGetNetworkStatsByUid(rawArgs: Any?, result: MethodChannel.Result) {
        if (!activity.isUsageAccessGranted()) {
            result.error("USAGE_ACCESS_REQUIRED", "Grant usage access in Settings.", null)
            return
        }
        val args    = rawArgs as? Map<*, *>
        val uid     = (args?.get("uid")     as? Number)?.toInt()  ?: run { result.error("INVALID_ARG", "uid required", null); return }
        val startMs = (args?.get("startMs") as? Number)?.toLong() ?: defaultStartMs()
        val endMs   = (args?.get("endMs")   as? Number)?.toLong() ?: System.currentTimeMillis()

        executor.execute {
            try {
                val bytes = queryBytesByUid(uid, startMs, endMs)
                mainHandler.post {
                    result.success(mapOf(
                        "mobileForegroundBytes" to bytes.mobileFg,
                        "mobileBackgroundBytes" to bytes.mobileBg,
                        "wifiForegroundBytes"   to bytes.wifiFg,
                        "wifiBackgroundBytes"   to bytes.wifiBg,
                        "periodStart"           to startMs,
                        "periodEnd"             to endMs,
                    ))
                }
            } catch (e: SecurityException) {
                mainHandler.post {
                    result.error("NETWORK_STATS_RESTRICTED", "Per-app data unavailable on this device.", e.message)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("NETWORK_STATS_FAILED", e.message, null)
                }
            }
        }
    }

    // ── core query helpers ───────────────────────────────────────────────────

    /**
     * Builds the complete per-app stats list for [startMs]..[endMs].
     * Icons are decoded only for this page; zero-usage apps are excluded.
     */
    private fun buildAppStatsList(startMs: Long, endMs: Long): List<Map<String, Any?>> {
        val pm  = activity.packageManager
        val nsm = activity.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        val byUid = mutableMapOf<Int, UsageBytes>()
        accumulateTransport(nsm, ConnectivityManager.TYPE_MOBILE, startMs, endMs, byUid)
        accumulateTransport(nsm, ConnectivityManager.TYPE_WIFI,   startMs, endMs, byUid)

        // Deduplicate UIDs: multiple packages may share a UID (common for system apps).
        // Keep only the first package encountered per UID.
        val seenUids = mutableSetOf<Int>()
        val result   = mutableListOf<Map<String, Any?>>()

        for (info in pm.getInstalledApplications(0)) {
            val uid = info.uid
            if (!seenUids.add(uid)) continue          // already handled this UID

            val bytes    = byUid[uid] ?: continue     // no usage → skip
            val totalAll = bytes.mobileFg + bytes.mobileBg + bytes.wifiFg + bytes.wifiBg
            if (totalAll == 0L) continue              // zero-usage → exclude per requirement

            val label    = pm.getApplicationLabel(info).toString()
            val isSystem = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val icon     = runCatching { drawableToBase64(pm.getApplicationIcon(info.packageName)) }.getOrNull()

            result += mapOf(
                "packageName"           to info.packageName,
                "appName"               to label,
                "mobileForegroundBytes" to bytes.mobileFg,
                "mobileBackgroundBytes" to bytes.mobileBg,
                "wifiForegroundBytes"   to bytes.wifiFg,
                "wifiBackgroundBytes"   to bytes.wifiBg,
                "foregroundTimeMs"      to 0L,   // populated by UsageStatsChannel merge in Dart
                "periodStart"           to startMs,
                "periodEnd"             to endMs,
                "appIconBase64"         to icon,
                "isSystemApp"           to isSystem,
            )
        }
        return result
    }

    /**
     * Returns bytes for a single [uid] across [startMs]..[endMs].
     * Used by the background spike-detection service.
     */
    private fun queryBytesByUid(uid: Int, startMs: Long, endMs: Long): UsageBytes {
        val nsm   = activity.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val bytes = UsageBytes()
        val byUid = mutableMapOf(uid to bytes)
        accumulateTransport(nsm, ConnectivityManager.TYPE_MOBILE, startMs, endMs, byUid, filterUid = uid)
        accumulateTransport(nsm, ConnectivityManager.TYPE_WIFI,   startMs, endMs, byUid, filterUid = uid)
        return bytes
    }

    /**
     * Iterates all [NetworkStats.Bucket]s for [transportType] and accumulates
     * rx+tx bytes into [byUid], splitting foreground vs background by bucket state.
     *
     * [filterUid] — when non-null, only buckets for that UID are accumulated (faster
     * path used by [queryBytesByUid]).
     */
    private fun accumulateTransport(
        nsm:          NetworkStatsManager,
        transportType: Int,
        startMs:      Long,
        endMs:        Long,
        byUid:        MutableMap<Int, UsageBytes>,
        filterUid:    Int? = null,
    ) {
        val stats  = nsm.querySummary(transportType, null, startMs, endMs)
        val bucket = NetworkStats.Bucket()
        while (stats.hasNextBucket()) {
            stats.getNextBucket(bucket)
            val uid = bucket.uid
            if (uid < 0) continue
            if (filterUid != null && uid != filterUid) continue

            val entry  = byUid.getOrPut(uid) { UsageBytes() }
            val bytes  = bucket.rxBytes + bucket.txBytes
            val isFg   = bucket.state == NetworkStats.Bucket.STATE_FOREGROUND
            // STATE_ALL (-1) means the driver didn't split: treat as foreground to avoid under-counting.
            val isBg   = bucket.state == NetworkStats.Bucket.STATE_DEFAULT

            when (transportType) {
                ConnectivityManager.TYPE_MOBILE -> if (isBg) entry.mobileBg += bytes else entry.mobileFg += bytes
                ConnectivityManager.TYPE_WIFI   -> if (isBg) entry.wifiBg   += bytes else entry.wifiFg   += bytes
            }
        }
        stats.close()
    }

    // ── icon encoding ────────────────────────────────────────────────────────

    private fun drawableToBase64(drawable: Drawable): String {
        val src = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val w = drawable.intrinsicWidth.coerceAtLeast(1)
            val h = drawable.intrinsicHeight.coerceAtLeast(1)
            Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
                val c = Canvas(it)
                drawable.setBounds(0, 0, c.width, c.height)
                drawable.draw(c)
            }
        }
        val scaled = Bitmap.createScaledBitmap(src, 96, 96, true)
        return ByteArrayOutputStream().use { out ->
            scaled.compress(Bitmap.CompressFormat.PNG, 90, out)
            Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        }
    }

    private fun defaultStartMs(): Long =
        System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000

    // ── data class ──────────────────────────────────────────────────────────

    data class UsageBytes(
        var mobileFg: Long = 0L,
        var mobileBg: Long = 0L,
        var wifiFg:   Long = 0L,
        var wifiBg:   Long = 0L,
    )
}
