package com.dataguardian.app.monitor

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Posts data-alert notifications and the persistent monitoring-status
 * notification from the background worker.
 */
class MonitorNotifier(private val context: Context) {

    fun show(id: Int, title: String, body: String) {
        if (!canPost()) return
        val notification = NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(launchIntent())
            .setAutoCancel(true)
            .build()
        notifySafely(id, notification)
    }

    /**
     * Persistent, tappable "monitoring is active" notification, refreshed on
     * each worker run. Restores the always-present status entry users relied on
     * (and its tap-to-open behavior) after the move off the foreground service.
     */
    fun showOngoingStatus(body: String) {
        if (!canPost()) return
        val notification = NotificationCompat.Builder(context, MONITOR_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle("Data Guardian")
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(launchIntent())
            .build()
        notifySafely(ID_ONGOING, notification)
    }

    fun cancelOngoing() {
        NotificationManagerCompat.from(context).cancel(ID_ONGOING)
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private fun launchIntent(): PendingIntent? {
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP) }
            ?: return null
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getActivity(context, 0, intent, flags)
    }

    private fun canPost(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED

    private fun notifySafely(id: Int, notification: android.app.Notification) {
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            // Notifications disabled at the OS level — nothing to do.
        }
    }

    companion object {
        private const val ALERT_CHANNEL_ID = "data_guardian_alerts"
        private const val MONITOR_CHANNEL_ID = "data_guardian_monitor"

        // Persistent status notification.
        const val ID_ONGOING = 1000

        // Alert notifications — stable IDs so re-fires replace rather than stack.
        const val ID_DAILY = 3001
        const val ID_WEEKLY = 3002
        const val ID_BACKGROUND = 3003
        const val ID_SPIKE = 3004
    }
}
