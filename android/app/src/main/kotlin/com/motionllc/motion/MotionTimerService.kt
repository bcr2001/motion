package com.motionllc.motion

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import kotlin.math.max

class MotionTimerService : Service() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == actionStop) {
            clearSavedState(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
            return START_NOT_STICKY
        }

        val state = when (intent?.action) {
            actionSync -> stateFromIntent(intent)
            else -> readSavedState(this)
        }
        if (state == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        saveState(this, state)
        val notification = buildNotification(state)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                } else {
                    0
                },
            )
        } else {
            startForeground(notificationId, notification)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(state: TimerNotificationState): Notification {
        val elapsedSeconds = state.currentElapsedSeconds()
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val launchPendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val statusText = if (state.isRunning) {
            "Tracking now"
        } else {
            "Timer paused"
        }
        val compactView = buildTimerView(state, elapsedSeconds)
        val expandedView = buildTimerView(state, elapsedSeconds)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setSmallIcon(R.drawable.ic_motion_timer_notification)
            .setContentTitle(state.subcategoryName)
            .setContentText(statusText)
            .setSubText("Motion timer")
            .setContentIntent(launchPendingIntent)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setColor(Color.rgb(0, 176, 240))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setUsesChronometer(false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder
                .setCustomContentView(compactView)
                .setCustomBigContentView(expandedView)
                .setStyle(Notification.DecoratedCustomViewStyle())
        } else {
            @Suppress("DEPRECATION")
            builder.setContent(compactView)
        }
        return builder.build()
    }

    private fun buildTimerView(
        state: TimerNotificationState,
        elapsedSeconds: Long,
    ): RemoteViews {
        return RemoteViews(packageName, R.layout.motion_timer_notification).apply {
            setTextViewText(R.id.timer_notification_subcategory, state.subcategoryName)
            if (state.isRunning) {
                setViewVisibility(R.id.timer_notification_elapsed, View.VISIBLE)
                setViewVisibility(R.id.timer_notification_paused_elapsed, View.GONE)
                setChronometer(
                    R.id.timer_notification_elapsed,
                    SystemClock.elapsedRealtime() - elapsedSeconds * 1000L,
                    null,
                    true,
                )
            } else {
                setViewVisibility(R.id.timer_notification_elapsed, View.GONE)
                setViewVisibility(R.id.timer_notification_paused_elapsed, View.VISIBLE)
                setTextViewText(
                    R.id.timer_notification_paused_elapsed,
                    formatDuration(elapsedSeconds),
                )
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            channelId,
            "Activity timer",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the activity timer while it is running or paused"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun stateFromIntent(intent: Intent): TimerNotificationState? {
        val mainCategoryName = intent.getStringExtra(extraMainCategory).orEmpty()
        val subcategoryName = intent.getStringExtra(extraSubcategory).orEmpty()
        if (mainCategoryName.isBlank() || subcategoryName.isBlank()) return null
        return TimerNotificationState(
            mainCategoryName = mainCategoryName,
            subcategoryName = subcategoryName,
            elapsedSeconds = max(0, intent.getIntExtra(extraElapsedSeconds, 0)),
            isRunning = intent.getBooleanExtra(extraIsRunning, false),
            synchronizedAtEpochMs = System.currentTimeMillis(),
        )
    }

    companion object {
        private const val channelId = "motion_activity_timer"
        private const val notificationId = 4102
        private const val preferencesName = "motion_activity_timer_notification"
        private const val actionSync = "com.motionllc.motion.timer.SYNC"
        private const val actionStop = "com.motionllc.motion.timer.STOP"
        private const val extraMainCategory = "main_category"
        private const val extraSubcategory = "subcategory"
        private const val extraElapsedSeconds = "elapsed_seconds"
        private const val extraIsRunning = "is_running"
        private const val keyActive = "active"
        private const val keySynchronizedAt = "synchronized_at"

        fun sync(
            context: Context,
            mainCategoryName: String,
            subcategoryName: String,
            elapsedSeconds: Int,
            isRunning: Boolean,
        ) {
            val intent = Intent(context, MotionTimerService::class.java).apply {
                action = actionSync
                putExtra(extraMainCategory, mainCategoryName)
                putExtra(extraSubcategory, subcategoryName)
                putExtra(extraElapsedSeconds, max(0, elapsedSeconds))
                putExtra(extraIsRunning, isRunning)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            clearSavedState(context)
            context.stopService(Intent(context, MotionTimerService::class.java))
        }

        private fun saveState(context: Context, state: TimerNotificationState) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(keyActive, true)
                .putString(extraMainCategory, state.mainCategoryName)
                .putString(extraSubcategory, state.subcategoryName)
                .putInt(extraElapsedSeconds, state.elapsedSeconds)
                .putBoolean(extraIsRunning, state.isRunning)
                .putLong(keySynchronizedAt, state.synchronizedAtEpochMs)
                .apply()
        }

        private fun readSavedState(context: Context): TimerNotificationState? {
            val preferences = context.getSharedPreferences(
                preferencesName,
                Context.MODE_PRIVATE,
            )
            if (!preferences.getBoolean(keyActive, false)) return null
            val mainCategoryName = preferences.getString(extraMainCategory, "").orEmpty()
            val subcategoryName = preferences.getString(extraSubcategory, "").orEmpty()
            if (mainCategoryName.isBlank() || subcategoryName.isBlank()) return null
            return TimerNotificationState(
                mainCategoryName = mainCategoryName,
                subcategoryName = subcategoryName,
                elapsedSeconds = preferences.getInt(extraElapsedSeconds, 0),
                isRunning = preferences.getBoolean(extraIsRunning, false),
                synchronizedAtEpochMs = preferences.getLong(
                    keySynchronizedAt,
                    System.currentTimeMillis(),
                ),
            )
        }

        private fun clearSavedState(context: Context) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .clear()
                .apply()
        }

        private fun formatDuration(totalSeconds: Long): String {
            val hours = totalSeconds / 3600
            val minutes = (totalSeconds % 3600) / 60
            val seconds = totalSeconds % 60
            return "%02d:%02d:%02d".format(hours, minutes, seconds)
        }
    }
}

private data class TimerNotificationState(
    val mainCategoryName: String,
    val subcategoryName: String,
    val elapsedSeconds: Int,
    val isRunning: Boolean,
    val synchronizedAtEpochMs: Long,
) {
    fun currentElapsedSeconds(): Long {
        if (!isRunning) return elapsedSeconds.toLong()
        val additionalSeconds = max(
            0L,
            (System.currentTimeMillis() - synchronizedAtEpochMs) / 1000L,
        )
        return elapsedSeconds + additionalSeconds
    }
}
