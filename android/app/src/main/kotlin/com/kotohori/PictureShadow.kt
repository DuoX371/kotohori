package com.kotohori

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Point
import android.graphics.Rect
import android.view.View
import java.io.File

/** What follows the finger while a picture is dragged: the picture itself, at most 200dp. */
class PictureShadow(view: View, file: File, density: Float) : View.DragShadowBuilder(view) {
    private val max = (200 * density).toInt()
    private val bitmap: Bitmap? = decode(file)
    private val width: Int
    private val height: Int

    init {
        val b = bitmap
        if (b == null) {
            width = max / 2
            height = max / 2
        } else {
            val scale = minOf(1f, max.toFloat() / maxOf(b.width, b.height))
            width = maxOf(1, (b.width * scale).toInt())
            height = maxOf(1, (b.height * scale).toInt())
        }
    }

    // Decoded small: a full-size illustration would be many megabytes.
    private fun decode(file: File): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= max) sample *= 2
        return BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    override fun onProvideShadowMetrics(size: Point, touch: Point) {
        size.set(width, height)
        touch.set(width / 2, height / 2)
    }

    override fun onDrawShadow(canvas: Canvas) {
        bitmap?.let { canvas.drawBitmap(it, null, Rect(0, 0, width, height), null) }
    }
}
