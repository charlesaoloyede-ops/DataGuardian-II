package com.dataguardian.app.monitor

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Reads the user's alert thresholds — written by Flutter's shared_preferences
 * plugin into the `FlutterSharedPreferences` file under `flutter.`-prefixed
 * keys — and records de-dup state plus a hand-off queue of alerts the worker
 * fired while the app was closed. The Dart side drains that queue into Hive so
 * the in-app Alerts Center stays complete.
 *
 * Only the single `user_preferences` JSON string is read from Flutter, so we
 * never depend on how the plugin encodes scalar int/double/bool values.
 */
class MonitorPrefs(context: Context) {

    private val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    data class Thresholds(
        val notificationsEnabled: Boolean,
        val dailyBytes: Long?,
        val weeklyBytes: Long?,
        val backgroundBytes: Long?,
        val spikeMultiplier: Double,
    )

    fun readThresholds(): Thresholds {
        val raw = prefs.getString("flutter.user_preferences", null)
            ?: return Thresholds(true, null, null, null, DEFAULT_SPIKE)
        return try {
            val json = JSONObject(raw)
            Thresholds(
                notificationsEnabled = json.optBoolean("notificationsEnabled", true),
                dailyBytes = json.optLongOrNull("dailyThresholdBytes"),
                weeklyBytes = json.optLongOrNull("weeklyThresholdBytes"),
                backgroundBytes = json.optLongOrNull("backgroundThresholdBytes"),
                spikeMultiplier = json.optDouble("spikeThresholdMultiplier", DEFAULT_SPIKE),
            )
        } catch (_: Exception) {
            Thresholds(true, null, null, null, DEFAULT_SPIKE)
        }
    }

    // ── de-dup: fire each alert type at most once per calendar day ────────────

    fun hasFired(type: String, dayKey: String): Boolean =
        prefs.getBoolean("flutter.monitor_fired_${type}_$dayKey", false)

    fun markFired(type: String, dayKey: String) {
        prefs.edit().putBoolean("flutter.monitor_fired_${type}_$dayKey", true).apply()
    }

    // ── pending-alert hand-off to the Dart Alerts Center ─────────────────────

    /**
     * Appends a fired alert to `flutter.pending_native_alerts` (a JSON array
     * string) which Dart drains on next foreground. Kept as a String so the
     * Flutter shared_preferences plugin reads it back cleanly.
     */
    fun enqueuePendingAlert(type: String, message: String, triggeredAtMs: Long) {
        val arr = try {
            JSONArray(prefs.getString("flutter.pending_native_alerts", "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        arr.put(
            JSONObject()
                .put("type", type)
                .put("message", message)
                .put("triggeredAtMs", triggeredAtMs)
        )
        prefs.edit().putString("flutter.pending_native_alerts", arr.toString()).apply()
    }

    private fun JSONObject.optLongOrNull(key: String): Long? =
        if (isNull(key) || !has(key)) null else optLong(key).takeIf { it > 0 }

    companion object {
        const val DEFAULT_SPIKE = 1.75
    }
}
