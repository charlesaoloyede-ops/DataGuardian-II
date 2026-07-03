package com.dataguardian.app.channels

import com.dataguardian.app.MainActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "com.dataguardian/usage_stats"

class UsageStatsChannel(private val activity: MainActivity) {

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUsageAccessGranted" ->
                        result.success(activity.isUsageAccessGranted())

                    "openUsageAccessSettings" -> {
                        activity.openUsageAccessSettings()
                        result.success(null)
                    }

                    "openAppDetailsSettings" -> {
                        activity.openAppDetailsSettings()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
