package com.example.dataguardian

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "data_guardian/usage"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Sorted (highest mobile usage first) list computed once per refresh; icons are decoded per-page on demand. */
    private var cachedRankedApps: List<RankedApp>? = null

    private data class RankedApp(
        val label: String,
        val packageName: String,
        val mobileBytes: Long,
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handleMethodCall)
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(hasUsageAccess())
            "openUsageAccessSettings" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            "getAppUsagePage" -> {
                if (!hasUsageAccess()) {
                    result.error("USAGE_ACCESS_REQUIRED", "Usage access has not been granted.", null)
                    return
                }
                val args = call.arguments as? Map<*, *>
                val offset = (args?.get("offset") as? Int) ?: 0
                val limit = (args?.get("limit") as? Int) ?: 10
                val reset = (args?.get("reset") as? Boolean) ?: false
                executor.execute {
                    try {
                        if (reset) cachedRankedApps = null
                        val page = buildAppUsagePage(offset, limit)
                        mainHandler.post { result.success(page) }
                    } catch (error: SecurityException) {
                        mainHandler.post {
                            result.error(
                                "USAGE_ACCESS_REQUIRED",
                                "Android denied network usage access. Enable Data Guardian in Usage access settings.",
                                error.message
                            )
                        }
                    } catch (error: Exception) {
                        mainHandler.post {
                            result.error("USAGE_READ_FAILED", "Could not read mobile data usage.", error.message)
                        }
                    }
                }
            }
            "setAppBudget" -> {
                val args = call.arguments as? Map<*, *>
                val packageName = args?.get("packageName") as? String
                val budgetBytes = (args?.get("budgetBytes") as? Number)?.toLong()
                if (packageName == null) {
                    result.error("INVALID_ARGUMENT", "packageName is required.", null)
                    return
                }
                UsageBudgetStore(applicationContext).setBudget(packageName, budgetBytes)
                result.success(null)
            }
            "getAppBudgets" -> result.success(UsageBudgetStore(applicationContext).allBudgets())
            "isIgnoringBatteryOptimizations" -> {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
            }
            "requestIgnoreBatteryOptimizations" -> {
                try {
                    startActivity(
                        Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                    )
                } catch (_: Exception) {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                }
                result.success(null)
            }
            "hasNotificationPermission" -> result.success(
                NotificationManagerCompat.from(applicationContext).areNotificationsEnabled()
            )
            "openAppDetailsSettings" -> {
                startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName")
                    )
                )
                result.success(null)
            }
            "requestNotificationPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                        1001
                    )
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        val appPage = Intent(
            Settings.ACTION_USAGE_ACCESS_SETTINGS,
            Uri.parse("package:$packageName")
        )
        try {
            startActivity(appPage)
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
        }
    }

    /** Builds (or reuses) the full app list ranked by mobile data usage, without decoding any icons. */
    private fun getOrRankApps(): List<RankedApp> {
        cachedRankedApps?.let { return it }
        val bytesByUid = NetworkUsage.queryBytesByUid(
            applicationContext,
            NetworkUsage.startOfMonthMillis(),
            System.currentTimeMillis()
        )
        val ranked = NetworkUsage.installedApps(applicationContext)
            .asSequence()
            .map { app ->
                RankedApp(
                    label = app.label,
                    packageName = app.packageName,
                    mobileBytes = bytesByUid[app.uid] ?: 0L,
                )
            }
            .sortedWith(
                compareByDescending<RankedApp> { it.mobileBytes }
                    .thenBy(String.CASE_INSENSITIVE_ORDER) { it.label }
            )
            .toList()
        cachedRankedApps = ranked
        return ranked
    }

    /** Returns one page of the ranked list with icons decoded only for that page, plus the total count. */
    private fun buildAppUsagePage(offset: Int, limit: Int): Map<String, Any> {
        val ranked = getOrRankApps()
        val packageManager = applicationContext.packageManager
        val page = ranked.drop(offset).take(limit).map { app ->
            val icon = try {
                drawableToBase64(packageManager.getApplicationIcon(app.packageName))
            } catch (_: PackageManager.NameNotFoundException) {
                null
            }
            mapOf(
                "name" to app.label,
                "packageName" to app.packageName,
                "mobileBytes" to app.mobileBytes,
                "icon" to icon,
            )
        }
        return mapOf("items" to page, "total" to ranked.size)
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val source = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = drawable.intrinsicWidth.coerceAtLeast(1)
            val height = drawable.intrinsicHeight.coerceAtLeast(1)
            Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        }
        val size = 96
        val bitmap = Bitmap.createScaledBitmap(source, size, size, true)
        return ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        }
    }
}
