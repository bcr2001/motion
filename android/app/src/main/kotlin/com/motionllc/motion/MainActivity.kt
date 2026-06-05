package com.motionllc.motion

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.charset.StandardCharsets

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "motion/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveCsv") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                if (fileName.isNullOrBlank() || content == null) {
                    result.error("invalid_args", "Missing CSV file name or content.", null)
                    return@setMethodCallHandler
                }

                try {
                    result.success(saveCsvToDownloads(fileName, content))
                } catch (error: Exception) {
                    result.error("download_save_failed", error.message, null)
                }
            }
    }

    private fun saveCsvToDownloads(fileName: String, content: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "text/csv")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = resolver.insert(
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                values
            ) ?: throw IllegalStateException("Could not create Downloads file.")

            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(content.toByteArray(StandardCharsets.UTF_8))
            } ?: throw IllegalStateException("Could not open Downloads file.")

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return "Downloads/$fileName"
        }

        val downloadsDirectory =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDirectory.exists()) {
            downloadsDirectory.mkdirs()
        }

        val file = File(downloadsDirectory, fileName)
        file.writeText(content, StandardCharsets.UTF_8)
        return file.absolutePath
    }
}
