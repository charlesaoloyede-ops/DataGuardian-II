package com.example.dataguardian

import android.content.Context

/** Tracks which budget thresholds and spike alerts have already been notified, so the worker doesn't repeat itself. */
class AlertStateStore(context: Context) {
    private val prefs = context.getSharedPreferences("data_guardian_alert_state", Context.MODE_PRIVATE)

    fun notifiedThresholds(packageName: String, monthKey: String): Set<Int> {
        val raw = prefs.getString(thresholdKey(packageName, monthKey), null) ?: return emptySet()
        return raw.split(",").filter { it.isNotBlank() }.map { it.toInt() }.toSet()
    }

    fun markThresholdNotified(packageName: String, monthKey: String, threshold: Int) {
        val current = notifiedThresholds(packageName, monthKey)
        val updated = (current + threshold).joinToString(",")
        prefs.edit().putString(thresholdKey(packageName, monthKey), updated).apply()
    }

    fun spikeAlreadyNotified(packageName: String, dayKey: String): Boolean =
        prefs.getString(spikeKey(packageName), null) == dayKey

    fun markSpikeNotified(packageName: String, dayKey: String) {
        prefs.edit().putString(spikeKey(packageName), dayKey).apply()
    }

    private fun thresholdKey(packageName: String, monthKey: String) = "thresholds_${packageName}_$monthKey"
    private fun spikeKey(packageName: String) = "spike_$packageName"
}
