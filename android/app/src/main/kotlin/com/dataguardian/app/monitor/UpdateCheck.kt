package com.dataguardian.app.monitor

import android.content.Context
import androidx.core.content.pm.PackageInfoCompat
import com.dataguardian.app.R
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
        // Read the Firebase project id and (client-side) API key from the
        // resources the google-services Gradle plugin generates from
        // google-services.json — which is gitignored — so neither is hardcoded
        // in source. These identify the client; access is gated by Firestore
        // Security Rules, not by keeping them secret.
        val projectId = context.getString(R.string.project_id)
        val apiKey = context.getString(R.string.google_api_key)
        val url = URL(
            "https://firestore.googleapis.com/v1/projects/$projectId" +
                "/databases/(default)/documents/app_config/latest_release?key=$apiKey",
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
}
