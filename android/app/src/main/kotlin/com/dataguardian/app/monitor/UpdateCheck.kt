package com.dataguardian.app.monitor

import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import androidx.core.content.pm.PackageInfoCompat
import com.dataguardian.app.R
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

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
            // Identify the calling app the same way the Firebase SDK does, so
            // the API key can be locked to this package + signing cert in Google
            // Cloud (Android application restriction) without 403-ing this call.
            setRequestProperty("X-Android-Package", context.packageName)
            signingCertSha1(context)?.let { setRequestProperty("X-Android-Cert", it) }
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

    /**
     * SHA-1 fingerprint of the running build's signing certificate, as uppercase
     * hex with no separators — the exact form the `X-Android-Cert` header wants.
     * Computed at runtime, so it matches whatever cert signed this APK (release
     * or debug). Register the release cert's SHA-1 in the API key's Android
     * restriction. Null if it can't be read (then the header is omitted).
     */
    private fun signingCertSha1(context: Context): String? = try {
        val pm = context.packageManager
        @Suppress("DEPRECATION")
        val signatures: Array<Signature>? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    .signingInfo?.apkContentsSigners
            } else {
                pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES).signatures
            }
        signatures?.firstOrNull()?.let { sig ->
            MessageDigest.getInstance("SHA-1")
                .digest(sig.toByteArray())
                .joinToString("") { "%02X".format(it) }
        }
    } catch (_: Exception) {
        null
    }
}
