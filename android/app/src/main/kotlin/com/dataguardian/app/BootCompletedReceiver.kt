package com.dataguardian.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts the background monitoring service after device reboot.
 * Full implementation in Phase 6 when flutter_background_service is wired up.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        // Phase 6: start flutter_background_service here
    }
}
