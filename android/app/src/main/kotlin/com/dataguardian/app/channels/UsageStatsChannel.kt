package com.dataguardian.app.channels

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.dataguardian.app.MainActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

private const val CHANNEL = "com.dataguardian/usage_stats"

/**
 * Bridges Flutter to Android's [UsageStatsManager] API.
 *
 * getUsageStats — returns per-app foreground screen-on time for a given window.
 *   The result list contains only apps that have non-zero foreground time, keyed
 *   by packageName so the Dart repository can merge them with network stats.
 *
 * isUsageAccessGranted / openUsageAccessSettings / openAppDetailsSettings are
 * thin wrappers that delegate to [MainActivity].
 */
class UsageStatsChannel(private val activity: MainActivity) {

    private val executor    = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUsageAccessGranted"   -> result.success(activity.isUsageAccessGranted())
                    "openUsageAccessSettings" -> { activity.openUsageAccessSettings(); result.success(null) }
                    "openAppDetailsSettings"  -> { activity.openAppDetailsSettings();  result.success(null) }
                    "getUsageStats"           -> handleGetUsageStats(call.arguments, result)
                    else                      -> result.notImplemented()
                }
            }
    }

    // ── getUsageStats ────────────────────────────────────────────────────────

    private fun handleGetUsageStats(rawArgs: Any?, result: MethodChannel.Result) {
        if (!activity.isUsageAccessGranted()) {
            result.error("USAGE_ACCESS_REQUIRED", "Grant usage access in Settings.", null)
            return
        }
        val args    = rawArgs as? Map<*, *>
        val startMs = (args?.get("startMs") as? Number)?.toLong() ?: defaultStartMs()
        val endMs   = (args?.get("endMs")   as? Number)?.toLong() ?: System.currentTimeMillis()

        executor.execute {
            try {
                val entries = queryUsageStats(startMs, endMs)
                mainHandler.post { result.success(entries) }
            } catch (e: SecurityException) {
                // Some OEMs restrict UsageStatsManager even with permission granted.
                mainHandler.post {
                    result.error("USAGE_STATS_RESTRICTED", "App usage time unavailable on this device.", e.message)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("USAGE_STATS_FAILED", e.message, null)
                }
            }
        }
    }

    /**
     * Aggregates [UsageStats] for the requested window.
     *
     * [UsageStatsManager.queryUsageStats] with [UsageStatsManager.INTERVAL_DAILY] returns
     * one record per app per calendar day. Multiple records for the same package are summed
     * so the Dart side receives one entry per app for the whole period.
     *
     * Only apps with foreground time > 0 are included.
     */
    private fun queryUsageStats(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val usm = activity.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        // INTERVAL_DAILY gives finer granularity; we aggregate across the whole window ourselves.
        val raw = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startMs, endMs)
            ?: return emptyList()

        // Aggregate by packageName (multiple daily records possible).
        val byPackage = mutableMapOf<String, Long>()  // packageName → totalForegroundMs
        for (stat in raw) {
            val existing = byPackage[stat.packageName] ?: 0L
            byPackage[stat.packageName] = existing + stat.totalTimeInForeground
        }

        return byPackage
            .filter { (_, time) -> time > 0L }
            .map    { (pkg,  time) -> mapOf("packageName" to pkg, "foregroundTimeMs" to time) }
    }

    private fun defaultStartMs(): Long =
        System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000
}
