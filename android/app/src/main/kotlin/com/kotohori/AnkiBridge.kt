package com.kotohori

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Talks to AnkiDroid's ContentProvider directly (the same provider the AnkiDroid
 * API library wraps; its only published build, api-v1.1.0, predates media support).
 * Contract: https://github.com/ankidroid/Anki-Android/blob/main/api/src/main/java/com/ichi2/anki/FlashCardsContract.kt
 */
class AnkiBridge(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "kotohori/anki"
        const val ANKI_PACKAGE = "com.ichi2.anki"
        const val PERMISSION = "com.ichi2.anki.permission.READ_WRITE_DATABASE"
        const val REQUEST_CODE = 4021
        private const val FIELD_SEP = "\u001f"
        private val AUTHORITY: Uri = Uri.parse("content://com.ichi2.anki.flashcards")
        private val NOTES: Uri = Uri.withAppendedPath(AUTHORITY, "notes")
        private val MODELS: Uri = Uri.withAppendedPath(AUTHORITY, "models")
        private val DECKS: Uri = Uri.withAppendedPath(AUTHORITY, "decks")
        private val MEDIA: Uri = Uri.withAppendedPath(AUTHORITY, "media")
    }

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pendingPermission: MethodChannel.Result? = null
    private val resolver get() = activity.contentResolver

    private fun isInstalled() = activity.packageManager.resolveContentProvider("com.ichi2.anki.flashcards", 0) != null
    private fun hasPermission() = activity.checkSelfPermission(PERMISSION) == PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(mapOf("installed" to isInstalled(), "permission" to hasPermission()))
            "requestPermission" -> {
                if (hasPermission()) return result.success(true)
                pendingPermission?.success(false)
                pendingPermission = result
                activity.requestPermissions(arrayOf(PERMISSION), REQUEST_CODE)
            }
            else -> background(result) { run(call) }
        }
    }

    /** Called from MainActivity.onRequestPermissionsResult. */
    fun onPermissionResult(granted: Boolean) {
        pendingPermission?.success(granted)
        pendingPermission = null
    }

    private fun run(call: MethodCall): Any? = when (call.method) {
        "decks" -> query(DECKS, null) { c ->
            mapOf("id" to c.getLong(c.getColumnIndexOrThrow("deck_id")), "name" to c.getString(c.getColumnIndexOrThrow("deck_name")))
        }
        "models" -> query(MODELS, null) { c ->
            mapOf(
                "id" to c.getLong(c.getColumnIndexOrThrow("_id")),
                "name" to c.getString(c.getColumnIndexOrThrow("name")),
                "fields" to c.getString(c.getColumnIndexOrThrow("field_names")).split(FIELD_SEP),
            )
        }
        // Selection uses Anki's browser search syntax; the Dart side builds and escapes it.
        "countNotes" -> resolver.query(NOTES, arrayOf("_id"), call.argument<String>("search")!!, null, null)?.use { it.count } ?: 0
        "addMedia" -> addMedia(File(call.argument<String>("path")!!), call.argument<String>("name")!!, call.argument<String>("kind")!!)
        "addNote" -> addNote(
            call.argument<Number>("modelId")!!.toLong(),
            call.argument<Number>("deckId")!!.toLong(),
            call.argument<List<String>>("fields")!!,
            call.argument<List<String>>("tags") ?: emptyList(),
        )
        "noteDecks" -> noteDecks(call.argument<String>("search")!!)
        "modelDesign" -> modelDesign(call.argument<Number>("id")!!.toLong())
        "addModel" -> addModel(
            call.argument<String>("name")!!,
            call.argument<List<String>>("fields")!!,
            call.argument<String>("css")!!,
            call.argument<List<Map<String, String>>>("cards")!!,
        )
        else -> throw UnsupportedOperationException(call.method)
    }

    /** Names of the decks holding the cards of notes matching [search] (read-only). */
    private fun noteDecks(search: String): List<String> {
        val noteIds: List<Long> = resolver.query(NOTES, arrayOf("_id"), search, null, null)?.use { c ->
            buildList<Long> { while (c.moveToNext()) add(c.getLong(0)) }
        } ?: return emptyList()
        if (noteIds.isEmpty()) return emptyList()
        val deckIds = linkedSetOf<Long>()
        for (id in noteIds) {
            resolver.query(Uri.withAppendedPath(NOTES, "$id/cards"), null, null, null, null)?.use { c ->
                val col = c.getColumnIndexOrThrow("deck_id")
                while (c.moveToNext()) deckIds.add(c.getLong(col))
            }
        }
        val names = query(DECKS, null) { c ->
            c.getLong(c.getColumnIndexOrThrow("deck_id")) to c.getString(c.getColumnIndexOrThrow("deck_name"))
        }.toMap()
        return deckIds.mapNotNull { names[it] }
    }

    /** A note type's look (read-only): CSS and each card template. */
    private fun modelDesign(id: Long): Map<String, Any?> {
        val modelUri = Uri.withAppendedPath(MODELS, id.toString())
        val css = resolver.query(modelUri, arrayOf("css"), null, null, null)?.use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        } ?: throw IllegalStateException("Note type not found")
        val cards = query(Uri.withAppendedPath(modelUri, "templates"), null) { c ->
            mapOf(
                "name" to c.getString(c.getColumnIndexOrThrow("card_template_name")),
                "front" to c.getString(c.getColumnIndexOrThrow("question_format")),
                "back" to c.getString(c.getColumnIndexOrThrow("answer_format")),
            )
        }
        return mapOf("css" to css, "cards" to cards)
    }

    /** New note type: fields + CSS, then each card template (same steps as AddContentApi.addNewCustomModel). */
    private fun addModel(name: String, fields: List<String>, css: String, cards: List<Map<String, String>>): Long {
        val values = ContentValues().apply {
            put("name", name)
            put("field_names", fields.joinToString(FIELD_SEP))
            put("num_cards", cards.size)
            put("css", css)
            put("sort_field_index", 0)
        }
        val modelUri = resolver.insert(MODELS, values) ?: throw IllegalStateException("AnkiDroid could not create the note type")
        val templates = Uri.withAppendedPath(modelUri, "templates")
        cards.forEachIndexed { i, card ->
            resolver.update(
                Uri.withAppendedPath(templates, i.toString()),
                ContentValues().apply {
                    put("card_template_name", card["name"]) // FlashCardsContract.CardTemplate.NAME
                    put("question_format", card["front"])
                    put("answer_format", card["back"])
                },
                null,
                null,
            )
        }
        return modelUri.lastPathSegment!!.toLong()
    }

    private fun <T> query(uri: Uri, selection: String?, row: (android.database.Cursor) -> T): List<T> =
        resolver.query(uri, null, selection, null, null)?.use { c ->
            buildList { while (c.moveToNext()) add(row(c)) }
        } ?: throw IllegalStateException("AnkiDroid did not answer (is it set up and opened at least once?)")

    /** Returns the field markup AnkiDroid expects: `<img src="...">` or `[sound:...]`. */
    private fun addMedia(file: File, preferredName: String, kind: String): String {
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", file)
        activity.grantUriPermission(ANKI_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            val values = ContentValues().apply {
                put("file_uri", uri.toString())
                put("preferred_name", preferredName.replace(" ", "_"))
            }
            val stored = resolver.insert(MEDIA, values)?.path ?: throw IllegalStateException("AnkiDroid rejected the media file")
            val name = File(stored).name
            return if (kind == "audio") "[sound:$name]" else "<img src=\"$name\">"
        } finally {
            activity.revokeUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun addNote(modelId: Long, deckId: Long, fields: List<String>, tags: List<String>): Long {
        val values = ContentValues().apply {
            put("mid", modelId)
            put("flds", fields.joinToString(FIELD_SEP))
            put("tags", tags.joinToString(" "))
        }
        val noteUri = resolver.insert(NOTES, values) ?: throw IllegalStateException("AnkiDroid could not add the note")
        // New cards go to the default deck; move them (same as AddContentApi.addNote).
        val cards = Uri.withAppendedPath(noteUri, "cards")
        resolver.query(cards, null, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                val ord = c.getString(c.getColumnIndexOrThrow("ord"))
                resolver.update(Uri.withAppendedPath(cards, ord), ContentValues().apply { put("deck_id", deckId) }, null, null)
            }
        }
        return noteUri.lastPathSegment!!.toLong()
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error(if (e is SecurityException) "permission" else "anki", e.message ?: e.toString(), null) }
            }
        }
    }
}
