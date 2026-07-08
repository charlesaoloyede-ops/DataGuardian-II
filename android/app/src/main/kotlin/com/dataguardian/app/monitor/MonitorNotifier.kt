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

    /**
     * Posts a data-alert notification. [type] (e.g. `daily`, `spike`, `test`)
     * tags both the analytics "shown" event and the launch intent, so a tap can
     * be attributed to the notification it came from.
     */
    fun show(id: Int, type: String, title: String, body: String) {
        if (!canPost()) return
        val notification = NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(launchIntent(id, type))
            .setAutoCancel(true)
            .build()
        notifySafely(id, notification)
        MonitorAnalytics.logNotificationShown(context, type)
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
            // No type → not counted in the notification click-through funnel;
            // this is a persistent status entry, not a push alert.
            .setContentIntent(launchIntent(ID_ONGOING, null))
            .build()
        notifySafely(ID_ONGOING, notification)
    }

    fun cancelOngoing() {
        NotificationManagerCompat.from(context).cancel(ID_ONGOING)
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private fun launchIntent(requestCode: Int, type: String?): PendingIntent? {
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                if (type != null) {
                    putExtra(EXTRA_FROM_NOTIFICATION, true)
                    putExtra(EXTRA_NOTIFICATION_TYPE, type)
                }
            }
            ?: return null
        // Distinct request code per notification id so each keeps its own extras.
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getActivity(context, requestCode, intent, flags)
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

        // Intent extras used to attribute an app-open to a notification tap.
        const val EXTRA_FROM_NOTIFICATION = "dg_from_notification"
        const val EXTRA_NOTIFICATION_TYPE = "dg_notification_type"

        // Persistent status notification.
        const val ID_ONGOING = 1000

        // User-triggered test notification.
        const val ID_TEST = 9999

        // Alert notifications — stable IDs so re-fires replace rather than stack.
        const val ID_DAILY = 3001
        const val ID_WEEKLY = 3002
        const val ID_BACKGROUND = 3003
        const val ID_SPIKE = 3004
    }
}
