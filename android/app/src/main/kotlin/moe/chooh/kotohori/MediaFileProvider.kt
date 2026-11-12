package moe.chooh.kotohori

import android.net.Uri
import androidx.core.content.FileProvider

/**
 * FileProvider for card media. Android's MIME table maps ".m4a" to audio/mpeg,
 * which makes AnkiDroid store our AAC clips with an ".mp3" name; report audio/mp4.
 */
class MediaFileProvider : FileProvider() {
    override fun getType(uri: Uri): String? =
        if (uri.path?.endsWith(".m4a") == true) "audio/mp4" else super.getType(uri)
}
