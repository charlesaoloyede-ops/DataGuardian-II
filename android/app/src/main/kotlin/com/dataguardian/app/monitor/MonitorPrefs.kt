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

    // ── conversion nudges (budget / limits not yet set) ──────────────────────

    /** True if the user has set a data budget for at least one app. */
    fun hasAnyAppBudget(): Boolean {
        val raw = prefs.getString("flutter.app_budgets", null) ?: return false
        return try {
            JSONObject(raw).length() > 0
        } catch (_: Exception) {
            false
        }
    }

    /** Last time (epoch ms) a given nudge was shown; 0 if never. Native-only
     *  keys (no `flutter.` prefix) so Dart's prefs never surface them. */
    fun nudgeLastMs(kind: String): Long = prefs.getLong("nudge_last_$kind", 0L)

    fun setNudgeLast(kind: String, ms: Long) {
        prefs.edit().putLong("nudge_last_$kind", ms).apply()
    }

    // ── data bundle monitoring (R2 exhaustion / R3 top-up) ───────────────────

    /**
     * A monitored data bundle, written by Dart under `flutter.data_bundle`.
     * Remaining = [anchorBalanceBytes] minus device-level mobile usage since
     * [anchorAtMs]; the anchor is re-set on self-report, manual re-sync, and
     * top-up (see the Dart BundleRepository). Null when nothing is monitored.
     */
    data class Bundle(
        val anchorBalanceBytes: Long,
        val anchorAtMs: Long,
        val expiryMs: Long,
        val sizeBytes: Long?,
        val source: String,
    )

    fun readBundle(): Bundle? {
        val raw = prefs.getString("flutter.data_bundle", null) ?: return null
        return try {
            val j = JSONObject(raw)
            val anchor = j.optLong("anchorBalanceBytes", -1L)
            val anchorAt = j.optLong("anchorAtMs", -1L)
            val expiry = j.optLong("expiryMs", -1L)
            if (anchor < 0 || anchorAt <= 0 || expiry <= 0) return null
            Bundle(
                anchorBalanceBytes = anchor,
                anchorAtMs = anchorAt,
                expiryMs = expiry,
                sizeBytes = if (j.has("sizeBytes") && !j.isNull("sizeBytes")) j.optLong("sizeBytes") else null,
                source = j.optString("source", "self_report"),
            )
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Whether a bundle alert of [kind] has already fired for the bundle with
     * anchor [anchorAtMs]. Re-anchoring (top-up / re-sync / new bundle) changes
     * the anchor, so the stored flag no longer matches and the alert re-arms —
     * a fresh bundle gets fresh alerts. Native-only keys (no `flutter.` prefix).
     */
    fun bundleAlertFired(kind: String, anchorAtMs: Long): Boolean =
        prefs.getLong("bundle_alert_anchor_$kind", 0L) == anchorAtMs &&
            prefs.getBoolean("bundle_alert_fired_$kind", false)

    fun setBundleAlertFired(kind: String, anchorAtMs: Long, fired: Boolean) {
        prefs.edit()
            .putLong("bundle_alert_anchor_$kind", anchorAtMs)
            .putBoolean("bundle_alert_fired_$kind", fired)
            .apply()
    }

    /** Epoch ms since the exhaustion risk last cleared for this anchor (0 = not
     *  clear / never). Used to re-arm R2 only after ≥24h back on track. */
    fun bundleRiskClearSince(anchorAtMs: Long): Long =
        if (prefs.getLong("bundle_risk_clear_anchor", 0L) == anchorAtMs)
            prefs.getLong("bundle_risk_clear_since", 0L) else 0L

    fun setBundleRiskClearSince(anchorAtMs: Long, since: Long) {
        prefs.edit()
            .putLong("bundle_risk_clear_anchor", anchorAtMs)
            .putLong("bundle_risk_clear_since", since)
            .apply()
    }

    // ── app-update push de-dup (at most once per day per pending version) ─────

    fun appUpdateNotifiedVersion(): Long = prefs.getLong("app_update_notified_version", -1L)
    fun appUpdateNotifiedDay(): String? = prefs.getString("app_update_notified_day", null)

    fun setAppUpdateNotified(versionCode: Long, dayKey: String) {
        prefs.edit()
            .putLong("app_update_notified_version", versionCode)
            .putString("app_update_notified_day", dayKey)
            .apply()
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
        const val DEFAULT_SPIKE = 1.5
    }
}
