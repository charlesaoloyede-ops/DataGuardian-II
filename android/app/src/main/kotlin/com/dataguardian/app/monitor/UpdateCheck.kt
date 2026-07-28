package com.dataguardian.app.monitor

import android.content.Context
import androidx.core.content.pm.PackageInfoCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Background check for a published sideload update, so users running a stale
 * build get notified even when they never open the app. Reads the same manifest
 * the in-app updater uses — the public-read Firestore doc
 * `app_config/latest_release` — over the REST API, so the worker needs no
 * Firebase SDK. Returns the available release when its versionCode is newer than
 * the installed build, else null. Every failure returns null (a missed check
 * just retries on the next worker run).
 */
object UpdateCheck {

    data class Available(val versionCode: Long, val versionName: String)

    fun check(context: Context): Available? = try {
        val url = URL(
            "https://firestore.googleapis.com/v1/projects/$PROJECT_ID" +
                "/databases/(default)/documents/app_config/latest_release?key=$API_KEY",
        )
        val conn = (url.openConnection() as HttpURLConnection).apply {
            connectTimeout = 8000
            readTimeout = 8000
            requestMethod = "GET"
        }
        try {
            if (conn.responseCode != 200) null
            else parse(
                conn.inputStream.bufferedReader().use { it.readText() },
                installedVersionCode(context),
            )
        } finally {
            conn.disconnect()
        }
    } catch (_: Exception) {
        null
    }

    /** Parses the Firestore REST document shape (typed field values). */
    private fun parse(body: String, installed: Long): Available? {
        val fields = JSONObject(body).optJSONObject("fields") ?: return null
        val versionCode = fields.optJSONObject("versionCode")
            ?.optString("integerValue")?.toLongOrNull() ?: return null
        val versionName =
            fields.optJSONObject("versionName")?.optString("stringValue") ?: ""
        return if (versionCode <= installed) null
        else Available(versionCode, versionName)
    }

    private fun installedVersionCode(context: Context): Long = try {
        val pi = context.packageManager.getPackageInfo(context.packageName, 0)
        PackageInfoCompat.getLongVersionCode(pi)
    } catch (_: Exception) {
        Long.MAX_VALUE // unknown installed version → never notify
    }

    // Public Android config mirrored from android/app/google-services.json
    // (already shipped inside the APK — these are not secrets). Kept here so the
    // worker needs no Firebase SDK. Update if the Firebase project changes.
    private const val PROJECT_ID = "data-guardian-2b988"
    private const val API_KEY = "AIzaSyDH16dkSnMM5kLg69RI4dguEpcUV58hm50"
}
