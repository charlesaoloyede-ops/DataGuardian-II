package com.dataguardian.app.monitor

import android.content.Context
import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics

/**
 * Logs background analytics events straight to Firebase from native code. The
 * WorkManager worker (and a notification tap that cold-starts the app) run with
 * no Flutter isolate alive, so these events can't go through the Dart layer.
 *
 * Collection is governed app-wide by `setAnalyticsCollectionEnabled()`, which
 * the Flutter layer sets from the user's opt-in (`shareAnonymousAnalytics`,
 * default off) and Firebase persists across processes. So when the user hasn't
 * opted in, these calls are dropped automatically — no separate gate is needed.
 */
object MonitorAnalytics {

    /** An alert actually fired (item 7: alerts/day + service-health signal). */
    fun logAlertFired(context: Context, type: String) =
        log(context, "alert_fired", type)

    /** A push notification was posted (item 5: click-through denominator). */
    fun logNotificationShown(context: Context, type: String) =
        log(context, "notification_shown", type)

    /** The user tapped a notification and it opened the app (item 5: numerator). */
    fun logNotificationOpened(context: Context, type: String) =
        log(context, "notification_opened", type)

    private fun log(context: Context, event: String, type: String) {
        try {
            val params = Bundle().apply { putString("type", type) }
            FirebaseAnalytics.getInstance(context).logEvent(event, params)
        } catch (_: Throwable) {
            // Analytics must never break monitoring.
        }
    }
}
