package com.motionllc.motion

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.media.AudioAttributes
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.widget.RemoteViews
import java.util.Date
import kotlin.math.max

class MotionTimerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var targetRunnable: Runnable? = null
    private var pausedProjectionRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == actionStop) {
            cancelTargetScheduling()
            cancelPausedProjectionRefresh()
            clearSavedState(this)
            dismissTargetAlert(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
            return START_NOT_STICKY
        }

        val savedState = readSavedState(this)
        val incomingState = when (intent?.action) {
            actionSync -> stateFromIntent(intent)
            actionTargetAlarm -> savedState
            else -> savedState
        }
        if (incomingState == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val state = mergeNativeAlertState(savedState, incomingState)
        if (savedState?.timerStartedAtEpochMs != state.timerStartedAtEpochMs) {
            dismissTargetAlert(this)
        }
        saveState(this, state)
        startAsForeground(state)
        schedulePausedProjectionRefresh(state)

        if (intent?.action == actionTargetAlarm ||
            intent?.getBooleanExtra(extraForceTargetAlert, false) == true
        ) {
            triggerTargetAlert(state)
        } else {
            scheduleTargetAlert(state)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        targetRunnable?.let(handler::removeCallbacks)
        targetRunnable = null
        cancelPausedProjectionRefresh()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startAsForeground(state: TimerNotificationState) {
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
    }

    private fun buildNotification(state: TimerNotificationState): Notification {
        val elapsedSeconds = state.currentElapsedSeconds()
        val launchPendingIntent = launchPendingIntent()
        val statusText = when {
            !state.isRunning -> "Paused at ${formatDuration(elapsedSeconds)}"
            else -> "Elapsed ${formatDuration(elapsedSeconds)}"
        }
        val compactView = buildTimerView(state, elapsedSeconds)
        val expandedView = buildTimerView(state, elapsedSeconds)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, timerChannelId)
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
            val hasTarget = state.targetSeconds > 0
            val targetReached = state.hasReachedTarget(elapsedSeconds)
            val remainingSeconds = state.targetSeconds - elapsedSeconds

            if (hasTarget && !targetReached && remainingSeconds > 0) {
                val expectedEndEpochMs =
                    System.currentTimeMillis() + remainingSeconds * 1000L
                val expectedEnd = android.text.format.DateFormat
                    .getTimeFormat(this@MotionTimerService)
                    .format(Date(expectedEndEpochMs))
                setTextViewText(
                    R.id.timer_notification_expected_end,
                    "Ends $expectedEnd",
                )
                setViewVisibility(R.id.timer_notification_expected_end, View.VISIBLE)
            } else {
                setViewVisibility(R.id.timer_notification_expected_end, View.GONE)
            }

            if (state.isRunning) {
                setViewVisibility(R.id.timer_notification_elapsed, View.VISIBLE)
                setViewVisibility(R.id.timer_notification_paused_elapsed, View.GONE)
                setChronometer(
                    R.id.timer_notification_elapsed,
                    SystemClock.elapsedRealtime() - elapsedSeconds * 1000L,
                    null,
                    true,
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.timer_notification_elapsed, false)
                }
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

    private fun scheduleTargetAlert(state: TimerNotificationState) {
        cancelTargetScheduling()
        if (!state.isRunning || state.targetSeconds <= 0 || state.targetAlertTriggered) {
            return
        }

        val remainingSeconds = state.targetSeconds - state.currentElapsedSeconds()
        if (remainingSeconds <= 0) {
            handler.post { triggerTargetAlert(state) }
            return
        }

        val expectedTimerStart = state.timerStartedAtEpochMs
        val runnable = Runnable {
            val currentState = readSavedState(this)
            if (currentState?.timerStartedAtEpochMs == expectedTimerStart) {
                triggerTargetAlert(currentState)
            }
        }
        targetRunnable = runnable
        handler.postDelayed(runnable, remainingSeconds * 1000L)
        scheduleSystemAlarm(
            timerStartedAtEpochMs = expectedTimerStart,
            triggerAtEpochMs = System.currentTimeMillis() + remainingSeconds * 1000L,
        )
    }

    private fun schedulePausedProjectionRefresh(state: TimerNotificationState) {
        cancelPausedProjectionRefresh()
        val elapsedSeconds = state.currentElapsedSeconds()
        if (state.isRunning ||
            state.targetSeconds <= 0 ||
            state.hasReachedTarget(elapsedSeconds)
        ) {
            return
        }

        val expectedTimerStart = state.timerStartedAtEpochMs
        val runnable = object : Runnable {
            override fun run() {
                val currentState = readSavedState(this@MotionTimerService) ?: return
                val currentElapsed = currentState.currentElapsedSeconds()
                if (currentState.timerStartedAtEpochMs != expectedTimerStart ||
                    currentState.isRunning ||
                    currentState.targetSeconds <= 0 ||
                    currentState.hasReachedTarget(currentElapsed)
                ) {
                    pausedProjectionRunnable = null
                    return
                }

                getSystemService(NotificationManager::class.java).notify(
                    notificationId,
                    buildNotification(currentState),
                )
                handler.postDelayed(this, pausedProjectionRefreshMs)
            }
        }
        pausedProjectionRunnable = runnable
        handler.postDelayed(runnable, pausedProjectionRefreshMs)
    }

    private fun cancelPausedProjectionRefresh() {
        pausedProjectionRunnable?.let(handler::removeCallbacks)
        pausedProjectionRunnable = null
    }

    private fun triggerTargetAlert(candidate: TimerNotificationState) {
        val currentState = readSavedState(this) ?: return
        if (currentState.timerStartedAtEpochMs != candidate.timerStartedAtEpochMs ||
            !currentState.isRunning ||
            currentState.targetSeconds <= 0 ||
            currentState.targetAlertTriggered
        ) {
            return
        }

        val elapsedSeconds = currentState.currentElapsedSeconds()
        if (!currentState.hasReachedTarget(elapsedSeconds)) {
            scheduleTargetAlert(currentState)
            return
        }

        val alertedState = currentState.copy(targetAlertTriggered = true)
        saveState(this, alertedState)
        cancelTargetScheduling()
        getSystemService(NotificationManager::class.java).apply {
            notify(notificationId, buildNotification(alertedState))
            notify(completionNotificationId, buildCompletionNotification(alertedState))
        }
        vibrateForCompletion()
    }

    private fun buildCompletionNotification(state: TimerNotificationState): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, completionChannelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setPriority(Notification.PRIORITY_HIGH)
                .setVibrate(completionVibrationPattern)
        }
        return builder
            .setSmallIcon(R.drawable.ic_motion_timer_notification)
            .setContentTitle("Session target reached")
            .setContentText("${state.subcategoryName} is now tracking overtime.")
            .setContentIntent(launchPendingIntent())
            .setCategory(Notification.CATEGORY_ALARM)
            .setColor(Color.rgb(0, 176, 240))
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .build()
    }

    private fun launchPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun scheduleSystemAlarm(
        timerStartedAtEpochMs: Long,
        triggerAtEpochMs: Long,
    ) {
        val alarmManager = getSystemService(AlarmManager::class.java)
        val pendingIntent = targetAlarmPendingIntent(this, timerStartedAtEpochMs)
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    !alarmManager.canScheduleExactAlarms() -> {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtEpochMs,
                        pendingIntent,
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtEpochMs,
                        pendingIntent,
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT -> {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtEpochMs,
                        pendingIntent,
                    )
                }
                else -> {
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtEpochMs,
                        pendingIntent,
                    )
                }
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtEpochMs,
                    pendingIntent,
                )
            } else {
                alarmManager.set(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtEpochMs,
                    pendingIntent,
                )
            }
        }
    }

    private fun vibrateForCompletion() {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createWaveform(completionVibrationPattern, -1)
            val attributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            vibrator.vibrate(effect, attributes)
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(completionVibrationPattern, -1)
        }
    }

    private fun cancelTargetScheduling() {
        targetRunnable?.let(handler::removeCallbacks)
        targetRunnable = null
        cancelScheduledAlarm(this)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val timerChannel = NotificationChannel(
            timerChannelId,
            "Activity timer",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows the activity timer while it is running or paused"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        val completionChannel = NotificationChannel(
            completionChannelId,
            "Timer complete",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alerts when a timed Motion session reaches its target"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).apply {
            legacyCompletionChannelIds.forEach(::deleteNotificationChannel)
            createNotificationChannels(listOf(timerChannel, completionChannel))
        }
    }

    private fun stateFromIntent(intent: Intent): TimerNotificationState? {
        val mainCategoryName = intent.getStringExtra(extraMainCategory).orEmpty()
        val subcategoryName = intent.getStringExtra(extraSubcategory).orEmpty()
        val timerStartedAtEpochMs = intent.getLongExtra(extraTimerStartedAtEpochMs, 0L)
        if (mainCategoryName.isBlank() ||
            subcategoryName.isBlank() ||
            timerStartedAtEpochMs <= 0
        ) {
            return null
        }
        return TimerNotificationState(
            mainCategoryName = mainCategoryName,
            subcategoryName = subcategoryName,
            elapsedSeconds = max(0, intent.getIntExtra(extraElapsedSeconds, 0)),
            isRunning = intent.getBooleanExtra(extraIsRunning, false),
            synchronizedAtEpochMs = System.currentTimeMillis(),
            timerStartedAtEpochMs = timerStartedAtEpochMs,
            targetSeconds = max(0, intent.getIntExtra(extraTargetSeconds, 0)),
            targetAlertTriggered =
                intent.getBooleanExtra(extraTargetAlertTriggered, false),
        )
    }

    private fun mergeNativeAlertState(
        savedState: TimerNotificationState?,
        incomingState: TimerNotificationState,
    ): TimerNotificationState {
        if (savedState?.timerStartedAtEpochMs != incomingState.timerStartedAtEpochMs) {
            return incomingState
        }
        return incomingState.copy(
            targetAlertTriggered =
                savedState.targetAlertTriggered || incomingState.targetAlertTriggered,
        )
    }

    companion object {
        private const val timerChannelId = "motion_activity_timer"
        private const val completionChannelId = "motion_timer_complete_v4"
        private val legacyCompletionChannelIds = listOf(
            "motion_timer_complete_v1",
            "motion_timer_complete_v2",
            "motion_timer_complete_v3",
        )
        private val completionVibrationPattern = longArrayOf(
            0,
            260,
            140,
            260,
            140,
            260,
            140,
            320,
        )
        private const val notificationId = 4102
        private const val completionNotificationId = 4103
        private const val alarmRequestCode = 4104
        private const val pausedProjectionRefreshMs = 60_000L
        private const val preferencesName = "motion_activity_timer_notification"
        private const val actionSync = "com.motionllc.motion.timer.SYNC"
        private const val actionTargetAlarm = "com.motionllc.motion.timer.TARGET_ALARM"
        private const val actionStop = "com.motionllc.motion.timer.STOP"
        private const val extraMainCategory = "main_category"
        private const val extraSubcategory = "subcategory"
        private const val extraElapsedSeconds = "elapsed_seconds"
        private const val extraIsRunning = "is_running"
        private const val extraTimerStartedAtEpochMs = "timer_started_at_epoch_ms"
        private const val extraTargetSeconds = "target_seconds"
        private const val extraTargetAlertTriggered = "target_alert_triggered"
        private const val extraForceTargetAlert = "force_target_alert"
        private const val keyActive = "active"
        private const val keySynchronizedAt = "synchronized_at"

        fun sync(
            context: Context,
            mainCategoryName: String,
            subcategoryName: String,
            elapsedSeconds: Int,
            isRunning: Boolean,
            timerStartedAtEpochMs: Long,
            targetSeconds: Int,
            targetAlertTriggered: Boolean,
            forceTargetAlert: Boolean,
        ) {
            val intent = Intent(context, MotionTimerService::class.java).apply {
                action = actionSync
                putExtra(extraMainCategory, mainCategoryName)
                putExtra(extraSubcategory, subcategoryName)
                putExtra(extraElapsedSeconds, max(0, elapsedSeconds))
                putExtra(extraIsRunning, isRunning)
                putExtra(extraTimerStartedAtEpochMs, timerStartedAtEpochMs)
                putExtra(extraTargetSeconds, max(0, targetSeconds))
                putExtra(extraTargetAlertTriggered, targetAlertTriggered)
                putExtra(extraForceTargetAlert, forceTargetAlert)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun handleScheduledTarget(context: Context, timerStartedAtEpochMs: Long) {
            val intent = Intent(context, MotionTimerService::class.java).apply {
                action = actionTargetAlarm
                putExtra(extraTimerStartedAtEpochMs, timerStartedAtEpochMs)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            cancelScheduledAlarm(context)
            clearSavedState(context)
            dismissTargetAlert(context)
            context.stopService(Intent(context, MotionTimerService::class.java))
        }

        fun dismissTargetAlert(context: Context) {
            context.getSystemService(NotificationManager::class.java)
                .cancel(completionNotificationId)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)
                    .defaultVibrator
                    .cancel()
            } else {
                @Suppress("DEPRECATION")
                (context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).cancel()
            }
        }

        private fun saveState(context: Context, state: TimerNotificationState) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(keyActive, true)
                .putString(extraMainCategory, state.mainCategoryName)
                .putString(extraSubcategory, state.subcategoryName)
                .putInt(extraElapsedSeconds, state.elapsedSeconds)
                .putBoolean(extraIsRunning, state.isRunning)
                .putLong(extraTimerStartedAtEpochMs, state.timerStartedAtEpochMs)
                .putInt(extraTargetSeconds, state.targetSeconds)
                .putBoolean(extraTargetAlertTriggered, state.targetAlertTriggered)
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
            val timerStartedAtEpochMs = preferences.getLong(extraTimerStartedAtEpochMs, 0L)
            if (mainCategoryName.isBlank() ||
                subcategoryName.isBlank() ||
                timerStartedAtEpochMs <= 0
            ) {
                return null
            }
            return TimerNotificationState(
                mainCategoryName = mainCategoryName,
                subcategoryName = subcategoryName,
                elapsedSeconds = preferences.getInt(extraElapsedSeconds, 0),
                isRunning = preferences.getBoolean(extraIsRunning, false),
                synchronizedAtEpochMs = preferences.getLong(
                    keySynchronizedAt,
                    System.currentTimeMillis(),
                ),
                timerStartedAtEpochMs = timerStartedAtEpochMs,
                targetSeconds = preferences.getInt(extraTargetSeconds, 0),
                targetAlertTriggered =
                    preferences.getBoolean(extraTargetAlertTriggered, false),
            )
        }

        private fun clearSavedState(context: Context) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .clear()
                .apply()
        }

        private fun targetAlarmPendingIntent(
            context: Context,
            timerStartedAtEpochMs: Long,
        ): PendingIntent {
            val intent = Intent(context, MotionTimerAlarmReceiver::class.java).apply {
                action = actionTargetAlarm
                putExtra(extraTimerStartedAtEpochMs, timerStartedAtEpochMs)
            }
            return PendingIntent.getBroadcast(
                context,
                alarmRequestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun cancelScheduledAlarm(context: Context) {
            val alarmManager = context.getSystemService(AlarmManager::class.java)
            alarmManager.cancel(targetAlarmPendingIntent(context, 0L))
        }

        private fun formatDuration(totalSeconds: Long): String {
            val safeSeconds = max(0L, totalSeconds)
            val hours = safeSeconds / 3600
            val minutes = (safeSeconds % 3600) / 60
            val seconds = safeSeconds % 60
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
    val timerStartedAtEpochMs: Long,
    val targetSeconds: Int,
    val targetAlertTriggered: Boolean,
) {
    fun currentElapsedSeconds(): Long {
        if (!isRunning) return elapsedSeconds.toLong()
        val additionalSeconds = max(
            0L,
            (System.currentTimeMillis() - synchronizedAtEpochMs) / 1000L,
        )
        return elapsedSeconds + additionalSeconds
    }

    fun hasReachedTarget(currentElapsedSeconds: Long): Boolean {
        return targetSeconds > 0 && currentElapsedSeconds >= targetSeconds
    }
}
