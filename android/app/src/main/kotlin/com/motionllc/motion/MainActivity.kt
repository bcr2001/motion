package com.motionllc.motion

import android.content.ContentValues
import android.Manifest
import android.content.pm.PackageManager
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
    private val homeWidgetChannel = "motion/home_widget"
    private val timerNotificationChannel = "motion/activity_timer_notification"
    private val notificationPermissionRequestCode = 4102
    private var pendingNotificationPermissionResult: MethodChannel.Result? = null

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, homeWidgetChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    MotionAnalyticsWidget.saveAndRefresh(
                        context = applicationContext,
                        todayXp = call.argument<Int>("todayXp") ?: 0,
                        targetXp = call.argument<Int>("targetXp") ?: 0,
                        currentStreak = call.argument<Int>("currentStreak") ?: 0,
                        badgeLevel = call.argument<String>("badgeLevel").orEmpty(),
                        badgeName = call.argument<String>("badgeName").orEmpty(),
                        progress = call.argument<Double>("progress") ?: 0.0,
                    )
                    result.success(null)
                } catch (error: Exception) {
                    result.error("widget_update_failed", error.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timerNotificationChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestNotificationPermission(result)
                    "sync" -> {
                        val mainCategoryName = call.argument<String>("mainCategoryName")
                        val subcategoryName = call.argument<String>("subcategoryName")
                        if (mainCategoryName.isNullOrBlank() || subcategoryName.isNullOrBlank()) {
                            result.error(
                                "invalid_timer_args",
                                "The timer category and subcategory are required.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        try {
                            MotionTimerService.sync(
                                context = applicationContext,
                                mainCategoryName = mainCategoryName,
                                subcategoryName = subcategoryName,
                                elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0,
                                isRunning = call.argument<Boolean>("isRunning") ?: false,
                            )
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("timer_notification_failed", error.message, null)
                        }
                    }
                    "stop" -> {
                        MotionTimerService.stop(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingNotificationPermissionResult != null) {
            result.error(
                "permission_request_active",
                "A notification permission request is already active.",
                null,
            )
            return
        }
        pendingNotificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != notificationPermissionRequestCode) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingNotificationPermissionResult?.success(granted)
        pendingNotificationPermissionResult = null
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
