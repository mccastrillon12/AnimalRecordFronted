package com.animalRecord.animal_record

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val SHARED_FILES_CHANNEL = "com.animalrecord/shared_files"
        const val FILE_DOWNLOAD_CHANNEL = "com.animalrecord/file_download"
        const val PDF_MIME_TYPE = "application/pdf"
        const val WRITE_STORAGE_PERMISSION_REQUEST = 8042
        const val DOWNLOAD_FOLDER_NAME = "Animal Record"
    }

    private data class PendingDownload(
        val fileName: String,
        val mimeType: String,
        val bytes: ByteArray,
        val result: MethodChannel.Result,
    )

    private val pendingFiles = mutableListOf<Map<String, String>>()
    private var methodChannel: MethodChannel? = null
    private var pendingDownload: PendingDownload? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARED_FILES_CHANNEL,
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedFiles" -> {
                    result.success(pendingFiles.toList())
                    pendingFiles.clear()
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_DOWNLOAD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType")
            val bytes = call.argument<ByteArray>("bytes")
            if (
                fileName.isNullOrBlank() ||
                mimeType.isNullOrBlank() ||
                bytes == null ||
                bytes.isEmpty()
            ) {
                result.error(
                    "INVALID_DOWNLOAD",
                    "No hay un archivo válido para descargar.",
                    null,
                )
                return@setMethodCallHandler
            }
            saveDownloadedFile(fileName, mimeType, bytes, result)
        }

        receiveSharedIntent(intent, notifyFlutter = false)
    }

    private fun saveDownloadedFile(
        fileName: String,
        mimeType: String,
        bytes: ByteArray,
        result: MethodChannel.Result,
    ) {
        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingDownload != null) {
                result.error(
                    "DOWNLOAD_IN_PROGRESS",
                    "Ya hay una descarga en curso.",
                    null,
                )
                return
            }
            pendingDownload = PendingDownload(fileName, mimeType, bytes, result)
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                WRITE_STORAGE_PERMISSION_REQUEST,
            )
            return
        }

        try {
            result.success(writeToPublicCollection(fileName, mimeType, bytes))
        } catch (error: Exception) {
            result.error(
                "DOWNLOAD_FAILED",
                "No fue posible descargar el archivo.",
                error.message,
            )
        }
    }

    private fun writeToPublicCollection(
        fileName: String,
        mimeType: String,
        bytes: ByteArray,
    ): String {
        val isImage = mimeType.startsWith("image/")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    if (isImage) {
                        "${Environment.DIRECTORY_PICTURES}/$DOWNLOAD_FOLDER_NAME"
                    } else {
                        "${Environment.DIRECTORY_DOWNLOADS}/$DOWNLOAD_FOLDER_NAME"
                    },
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val destination = contentResolver.insert(
                if (isImage) {
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                } else {
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI
                },
                values,
            ) ?: throw IllegalStateException("No se pudo crear el archivo de descarga.")

            try {
                contentResolver.openOutputStream(destination, "w")?.use { output ->
                    output.write(bytes)
                } ?: throw IllegalStateException("No se pudo abrir el archivo de descarga.")

                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(destination, values, null, null)
                return destination.toString()
            } catch (error: Exception) {
                contentResolver.delete(destination, null, null)
                throw error
            }
        }

        @Suppress("DEPRECATION")
        val publicDirectory = Environment.getExternalStoragePublicDirectory(
            if (isImage) Environment.DIRECTORY_PICTURES else Environment.DIRECTORY_DOWNLOADS,
        )
        val appDirectory = File(publicDirectory, DOWNLOAD_FOLDER_NAME).apply {
            if (!exists() && !mkdirs()) {
                throw IllegalStateException("No se pudo crear la carpeta de descargas.")
            }
        }
        val destination = uniqueDestination(appDirectory, fileName)
        FileOutputStream(destination).use { output -> output.write(bytes) }
        if (isImage) {
            MediaScannerConnection.scanFile(
                this,
                arrayOf(destination.absolutePath),
                arrayOf(mimeType),
                null,
            )
        }
        return destination.absolutePath
    }

    private fun uniqueDestination(directory: File, fileName: String): File {
        val initial = File(directory, fileName)
        if (!initial.exists()) return initial

        val extensionIndex = fileName.lastIndexOf('.')
        val baseName = if (extensionIndex > 0) {
            fileName.substring(0, extensionIndex)
        } else {
            fileName
        }
        val extension = if (extensionIndex > 0) {
            fileName.substring(extensionIndex)
        } else {
            ""
        }
        var copyNumber = 1
        var candidate: File
        do {
            candidate = File(directory, "$baseName ($copyNumber)$extension")
            copyNumber++
        } while (candidate.exists())
        return candidate
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != WRITE_STORAGE_PERMISSION_REQUEST) return

        val download = pendingDownload ?: return
        pendingDownload = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            saveDownloadedFile(
                download.fileName,
                download.mimeType,
                download.bytes,
                download.result,
            )
        } else {
            download.result.error(
                "STORAGE_PERMISSION_DENIED",
                "Se necesita permiso para guardar el archivo en Descargas.",
                null,
            )
        }
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
