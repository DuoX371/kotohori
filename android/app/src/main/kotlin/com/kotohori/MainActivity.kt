package com.kotohori

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.StatFs
import android.util.Rational
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var anki: AnkiBridge? = null
    private var documents: Documents? = null

    // Mini player (picture-in-picture): allowed only while a video plays (set from Dart).
    private var pip: MethodChannel? = null
    private var pipEnabled = false
    private var pipAspect = Rational(16, 9)
    private var pipPlaying = false

    // Mini window buttons → Dart ("previous" / "toggle" / "next").
    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            intent.getStringExtra("cmd")?.let { pip?.invokeMethod("action", it) }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun pipAction(cmd: String, code: Int, icon: Int, title: String) = RemoteAction(
        Icon.createWithResource(this, icon), title, title,
        PendingIntent.getBroadcast(
            this, code,
            Intent(PIP_ACTION).setPackage(packageName).putExtra("cmd", cmd),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        ),
    )

    @RequiresApi(Build.VERSION_CODES.O)
    private fun pipParams(): PictureInPictureParams =
        PictureInPictureParams.Builder().setAspectRatio(pipAspect).setActions(
            listOf(
                pipAction("previous", 1, R.drawable.ic_pip_previous, "Previous line"),
                if (pipPlaying) pipAction("toggle", 2, R.drawable.ic_pip_pause, "Pause")
                else pipAction("toggle", 2, R.drawable.ic_pip_play, "Play"),
                pipAction("next", 3, R.drawable.ic_pip_next, "Next line"),
            ),
        ).apply {
            // Android 12+: enter smoothly on Home by itself.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) setAutoEnterEnabled(pipEnabled)
        }.build()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "kotohori/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "freeBytes" -> try {
                        result.success(StatFs(call.argument<String>("path")!!).availableBytes)
                    } catch (e: Exception) {
                        result.error("statfs", e.message, null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(messenger, "kotohori/app").setMethodCallHandler { call, result ->
            if (call.method == "version") {
                result.success(packageManager.getPackageInfo(packageName, 0).versionName)
            } else {
                result.notImplemented()
            }
        }
        pip = MethodChannel(messenger, "kotohori/pip").apply {
            setMethodCallHandler { call, result ->
                if (call.method != "configure") return@setMethodCallHandler result.notImplemented()
                pipEnabled = call.argument<Boolean>("enabled") == true
                pipPlaying = call.argument<Boolean>("playing") == true
                val w = call.argument<Int>("width") ?: 0
                val h = call.argument<Int>("height") ?: 0
                if (w > 0 && h > 0) {
                    // Android only accepts ratios between 1:2.39 and 2.39:1.
                    val r = (w.toDouble() / h).coerceIn(1 / 2.38, 2.38)
                    pipAspect = Rational((r * 1000).toInt(), 1000)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) setPictureInPictureParams(pipParams())
                result.success(null)
            }
        }
        ContextCompat.registerReceiver(
            this, pipReceiver, IntentFilter(PIP_ACTION), ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        anki = AnkiBridge(this).also { MethodChannel(messenger, AnkiBridge.CHANNEL).setMethodCallHandler(it) }
        documents = Documents(this).also { MethodChannel(messenger, Documents.CHANNEL).setMethodCallHandler(it) }
        MethodChannel(messenger, MediaTools.CHANNEL).setMethodCallHandler(MediaTools(applicationContext))
    }

    /**
     * Keyboard shortcuts (Space, arrows) must work on the first press. By default the
     * Flutter view only takes key focus when Android leaves touch mode, which uses up
     * that first key press. Keeping it focusable in touch mode avoids that.
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return
        findViewById<android.view.View>(FLUTTER_VIEW_ID)?.apply {
            isFocusableInTouchMode = true
            if (!hasFocus()) requestFocus()
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        runCatching { unregisterReceiver(pipReceiver) }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private companion object {
        const val PIP_ACTION = "com.kotohori.PIP_ACTION"
    }

    /** Android 8–11 have no auto-enter: go into the mini player when the user leaves (Home). */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (pipEnabled && Build.VERSION.SDK_INT in Build.VERSION_CODES.O until Build.VERSION_CODES.S) {
            enterPictureInPictureMode(pipParams())
        }
    }

    override fun onPictureInPictureModeChanged(inPip: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(inPip, newConfig)
        // Leaving PiP while stopped means the mini window was closed (not expanded).
        val closed = !inPip && !lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
        pip?.invokeMethod("changed", mapOf("inPip" to inPip, "closed" to closed))
    }

    @Deprecated("FlutterActivity still routes results through onActivityResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == Documents.REQUEST_CODE) documents?.onResult(resultCode, data)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == AnkiBridge.REQUEST_CODE) {
            anki?.onPermissionResult(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        }
    }
}
