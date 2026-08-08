package com.animalRecord.animal_record

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val CHANNEL = "com.animalrecord/shared_files"
        const val PDF_MIME_TYPE = "application/pdf"
    }

    private val pendingFiles = mutableListOf<Map<String, String>>()
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedFiles" -> {
                    result.success(pendingFiles.toList())
                    pendingFiles.clear()
                }
                else -> result.notImplemented()
            }
        }

        receiveSharedIntent(intent, notifyFlutter = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receiveSharedIntent(intent, notifyFlutter = true)
    }

    private fun receiveSharedIntent(intent: Intent?, notifyFlutter: Boolean) {
        val sharedUris = when (intent?.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamUri(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamUris(intent)
            else -> emptyList()
        }

        val files = sharedUris.mapNotNull(::copySharedFile)
        if (files.isEmpty()) return

        if (notifyFlutter) {
            methodChannel?.invokeMethod("sharedFilesReceived", files)
        } else {
            pendingFiles.addAll(files)
        }
    }

    @Suppress("DEPRECATION")
    private fun streamUri(intent: Intent): Uri? {
        return intent.getParcelableExtra(Intent.EXTRA_STREAM)
    }

    @Suppress("DEPRECATION")
    private fun streamUris(intent: Intent): List<Uri> {
        return intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty()
    }

    private fun copySharedFile(uri: Uri): Map<String, String>? {
        val mimeType = contentResolver.getType(uri) ?: return null
        if (!mimeType.startsWith("image/") && mimeType != PDF_MIME_TYPE) return null

        val originalName = queryDisplayName(uri) ?: defaultName(mimeType)
        val safeName = originalName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        val sharedDirectory = File(cacheDir, "shared_files").apply { mkdirs() }
        val destination = File(sharedDirectory, "${UUID.randomUUID()}-$safeName")

        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(destination).use { output -> input.copyTo(output) }
            } ?: return null

            mapOf(
                "path" to destination.absolutePath,
                "name" to originalName,
                "mimeType" to mimeType,
            )
        } catch (_: Exception) {
            destination.delete()
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, null, null, null, null)
            val nameIndex = cursor?.getColumnIndex(OpenableColumns.DISPLAY_NAME) ?: -1
            if (cursor?.moveToFirst() == true && nameIndex >= 0) {
                cursor?.getString(nameIndex)
            } else {
                null
            }
        } finally {
            cursor?.close()
        }
    }

    private fun defaultName(mimeType: String): String {
        return if (mimeType == PDF_MIME_TYPE) "document.pdf" else "image"
    }
}
