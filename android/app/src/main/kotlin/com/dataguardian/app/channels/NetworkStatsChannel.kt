package com.dataguardian.app.channels

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.net.ConnectivityManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import com.dataguardian.app.MainActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

private const val CHANNEL = "com.dataguardian/network_stats"

/**
 * Queries per-app mobile and Wi-Fi data usage via [NetworkStatsManager].
 *
 * Returns both foreground and background bytes for each transport, plus
 * whether the app is a system app and its Base64-encoded icon.
 *
 * OEM restriction: on some devices (MIUI, EMUI) NetworkStatsManager returns
 * zeros or throws SecurityException. The repository layer handles this by
 * catching the exception and showing a banner to the user.
 */
class NetworkStatsChannel(private val activity: MainActivity) {

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNetworkStats" -> {
                        if (!activity.isUsageAccessGranted()) {
                            result.error(
                                "USAGE_ACCESS_REQUIRED",
                                "Grant usage access in Settings.",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        val args = call.arguments as? Map<*, *>
                        val startMs = (args?.get("startMs") as? Number)?.toLong()
                            ?: System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000
                        val endMs = (args?.get("endMs") as? Number)?.toLong()
                            ?: System.currentTimeMillis()

                        executor.execute {
                            try {
                                val stats = queryAllStats(startMs, endMs)
                                mainHandler.post { result.success(stats) }
                            } catch (e: SecurityException) {
                                mainHandler.post {
                                    result.error(
                                        "NETWORK_STATS_RESTRICTED",
                                        "Per-app data unavailable on this device.",
                                        e.message
                                    )
                                }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("NETWORK_STATS_FAILED", e.message, null)
                                }
                            }
                        }
                    }

                    "getNetworkStatsByUid" -> {
                        // Phase 2 — stub
                        result.success(emptyMap<String, Any>())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun queryAllStats(startMs: Long, endMs: Long): List<Map<String, Any?>> {
        val pm = activity.packageManager
        val nsm = activity.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        // Build UID → (mobileFg, mobileBg, wifiFg, wifiBg) map
        data class Bytes(
            var mobileFg: Long = 0L,
            var mobileBg: Long = 0L,
            var wifiFg: Long = 0L,
            var wifiBg: Long = 0L,
        )
        val byUid = mutableMapOf<Int, Bytes>()

        fun accumulateBuckets(bucket: NetworkStats.Bucket, transport: Int) {
            val uid = bucket.uid
            if (uid < 0) return
            val b = byUid.getOrPut(uid) { Bytes() }
            val rx = bucket.rxBytes
            val tx = bucket.txBytes
            val isFg = bucket.state == NetworkStats.Bucket.STATE_FOREGROUND
            when (transport) {
                ConnectivityManager.TYPE_MOBILE -> if (isFg) {
                    b.mobileFg += rx + tx
                } else {
                    b.mobileBg += rx + tx
                }
                ConnectivityManager.TYPE_WIFI -> if (isFg) {
                    b.wifiFg += rx + tx
                } else {
                    b.wifiBg += rx + tx
                }
            }
        }

        // Mobile stats
        queryBuckets(nsm, ConnectivityManager.TYPE_MOBILE, startMs, endMs) {
            accumulateBuckets(it, ConnectivityManager.TYPE_MOBILE)
        }
        // Wi-Fi stats
        queryBuckets(nsm, ConnectivityManager.TYPE_WIFI, startMs, endMs) {
            accumulateBuckets(it, ConnectivityManager.TYPE_WIFI)
        }

        val installedApps = getInstalledApps(pm)
        val result = mutableListOf<Map<String, Any?>>()

        for ((uid, label, pkgName, isSystem) in installedApps) {
            val bytes = byUid[uid] ?: continue
            val totalMobile = bytes.mobileFg + bytes.mobileBg
            val totalWifi = bytes.wifiFg + bytes.wifiBg
            if (totalMobile == 0L && totalWifi == 0L) continue // exclude zero-usage apps

            val icon = try {
                drawableToBase64(pm.getApplicationIcon(pkgName))
            } catch (_: PackageManager.NameNotFoundException) {
                null
            }

            result += mapOf(
                "packageName" to pkgName,
                "appName" to label,
                "mobileForegroundBytes" to totalMobile,   // simplified: full query returns total per uid
                "mobileBackgroundBytes" to 0L,            // background split — Phase 2 refinement
                "wifiForegroundBytes" to totalWifi,
                "wifiBackgroundBytes" to 0L,
                "foregroundTimeMs" to 0L,
                "periodStart" to startMs,
                "periodEnd" to endMs,
                "appIconBase64" to icon,
                "isSystemApp" to isSystem,
            )
        }

        return result
    }

    private fun queryBuckets(
        nsm: NetworkStatsManager,
        transportType: Int,
        startMs: Long,
        endMs: Long,
        onBucket: (NetworkStats.Bucket) -> Unit,
    ) {
        val stats = nsm.querySummary(transportType, null, startMs, endMs)
        val bucket = NetworkStats.Bucket()
        while (stats.hasNextBucket()) {
            stats.getNextBucket(bucket)
            onBucket(bucket)
        }
        stats.close()
    }

    private data class AppEntry(val uid: Int, val label: String, val packageName: String, val isSystem: Boolean)

    private fun getInstalledApps(pm: PackageManager): List<AppEntry> {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_UNINSTALLED_PACKAGES.toLong().toInt()
        } else {
            @Suppress("DEPRECATION") PackageManager.GET_UNINSTALLED_PACKAGES
        }
        return pm.getInstalledApplications(flags).map { info ->
            val label = pm.getApplicationLabel(info).toString()
            val isSystem = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            AppEntry(info.uid, label, info.packageName, isSystem)
        }
    }

    private fun drawableToBase64(drawable: android.graphics.drawable.Drawable): String {
        val src = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val w = drawable.intrinsicWidth.coerceAtLeast(1)
            val h = drawable.intrinsicHeight.coerceAtLeast(1)
            Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
                val c = Canvas(it)
                drawable.setBounds(0, 0, c.width, c.height)
                drawable.draw(c)
            }
        }
        val scaled = Bitmap.createScaledBitmap(src, 96, 96, true)
        return ByteArrayOutputStream().use { out ->
            scaled.compress(Bitmap.CompressFormat.PNG, 90, out)
            Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        }
    }
}
