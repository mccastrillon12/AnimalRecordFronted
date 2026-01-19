package com.animalRecord.animal_record

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.animalRecord.animal_record/share"
    private var sharedFiles: List<String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFiles" -> {
                    result.success(sharedFiles)
                    sharedFiles = null
                }
                else -> result.notImplemented()
            }
        }
        
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_SEND -> handleSendSingle(intent)
            Intent.ACTION_SEND_MULTIPLE -> handleSendMultiple(intent)
        }
    }

    private fun handleSendSingle(intent: Intent) {
        (intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))?.let { uri ->
            val path = getPathFromUri(uri)
            if (path != null) {
                sharedFiles = listOf(path)
                notifyFlutter()
            }
        }
    }

    private fun handleSendMultiple(intent: Intent) {
        intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris ->
            val paths = uris.mapNotNull { getPathFromUri(it) }
            if (paths.isNotEmpty()) {
                sharedFiles = paths
                notifyFlutter()
            }
        }
    }

    private fun getPathFromUri(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val fileName = getFileNameFromUri(uri)
            val outputFile = java.io.File(cacheDir, fileName)
            
            inputStream?.use { input ->
                outputFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            outputFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun getFileNameFromUri(uri: Uri): String {
        var fileName = "shared_file_${System.currentTimeMillis()}"
        
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    fileName = cursor.getString(nameIndex)
                }
            }
        }
        
        return fileName
    }

    private fun notifyFlutter() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onSharedFiles", null)
        }
    }
}
