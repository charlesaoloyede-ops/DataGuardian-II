package com.dataguardian.app.monitor

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Posts data-alert notifications from the background worker to the existing
 * `data_guardian_alerts` channel (created in DataGuardianApplication).
 */
class MonitorNotifier(private val context: Context) {

    fun show(id: Int, title: String, body: String) {
        // POST_NOTIFICATIONS is runtime-gated on API 33+; skip silently if not granted.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            // Notifications disabled at the OS level — nothing to do.
        }
    }

    companion object {
        private const val CHANNEL_ID = "data_guardian_alerts"

        // Stable IDs so re-fires replace rather than stack.
        const val ID_DAILY = 3001
        const val ID_WEEKLY = 3002
        const val ID_BACKGROUND = 3003
        const val ID_SPIKE = 3004
    }
}
