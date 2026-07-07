package com.dataguardian.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import id.flutter.flutter_background_service.BackgroundService

/**
 * Restarts the background data-monitoring service after device reboot.
 *
 * flutter_background_service registers [BackgroundService] as a foreground
 * service.  Starting it directly here causes the plugin to boot a headless
 * Flutter engine and invoke [onServiceStart] from the Dart side.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val serviceIntent = Intent(context, BackgroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
