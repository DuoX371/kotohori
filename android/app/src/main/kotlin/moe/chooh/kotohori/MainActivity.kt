package moe.chooh.kotohori

import android.content.Intent
import android.content.pm.PackageManager
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var anki: AnkiBridge? = null
    private var documents: Documents? = null

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
