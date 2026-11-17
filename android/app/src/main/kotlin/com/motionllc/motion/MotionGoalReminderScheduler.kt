package com.motionllc.motion

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import java.util.Calendar

data class MotionGoalStartReminder(
    val goalId: Int,
    val name: String,
    val entryType: String,
    val year: Int,
    val month: Int,
    val day: Int,
) {
    val signature: String
        get() = "$goalId:$year-$month-$day:$entryType"
}

object MotionGoalReminderScheduler {
    private const val preferencesName = "motion_goal_start_reminders"
    private const val keyIds = "scheduled_goal_ids"
    private const val reminderChannelId = "motion_goal_start_reminders_v1"
    private const val debugNotificationId = 61999
    private const val reminderHour = 9

    fun sync(context: Context, reminders: List<MotionGoalStartReminder>) {
        val appContext = context.applicationContext
        val preferences = appContext.getSharedPreferences(
            preferencesName,
            Context.MODE_PRIVATE,
        )
        val previousIds = preferences.getStringSet(keyIds, emptySet()).orEmpty()
            .mapNotNull(String::toIntOrNull)
            .toSet()
        val incomingIds = reminders.map { it.goalId }.toSet()

        (previousIds - incomingIds).forEach { goalId ->
            cancelAlarm(appContext, goalId)
            clearReminder(preferences, goalId)
        }

        reminders.forEach { reminder ->
            saveReminder(preferences, reminder)
            val deliveredSignature = preferences.getString(
                deliveredKey(reminder.goalId),
                null,
            )
            if (deliveredSignature == reminder.signature) {
                cancelAlarm(appContext, reminder.goalId)
            } else {
                schedule(appContext, reminder)
            }
        }

        preferences.edit()
            .putStringSet(keyIds, incomingIds.map(Int::toString).toSet())
            .apply()
    }

    fun reschedulePersisted(context: Context) {
        val appContext = context.applicationContext
        val preferences = appContext.getSharedPreferences(
            preferencesName,
            Context.MODE_PRIVATE,
        )
        preferences.getStringSet(keyIds, emptySet()).orEmpty()
            .mapNotNull(String::toIntOrNull)
            .mapNotNull { readReminder(preferences, it) }
            .forEach { reminder ->
                if (preferences.getString(deliveredKey(reminder.goalId), null) !=
                    reminder.signature
                ) {
                    schedule(appContext, reminder)
                }
            }
    }

    fun deliver(context: Context, reminder: MotionGoalStartReminder) {
        val appContext = context.applicationContext
        createNotificationChannel(appContext)
        val manager = appContext.getSystemService(NotificationManager::class.java)
        manager.notify(notificationId(reminder.goalId), buildNotification(appContext, reminder))
        appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putString(deliveredKey(reminder.goalId), reminder.signature)
            .apply()
        cancelAlarm(appContext, reminder.goalId)
    }

    fun showDebugNotification(context: Context) {
        val appContext = context.applicationContext
        createNotificationChannel(appContext)
        val reminder = MotionGoalStartReminder(
            goalId = debugNotificationId,
            name = "Your Motion start reminder is working",
            entryType = "goal",
            year = Calendar.getInstance().get(Calendar.YEAR),
            month = Calendar.getInstance().get(Calendar.MONTH) + 1,
            day = Calendar.getInstance().get(Calendar.DAY_OF_MONTH),
        )
        appContext.getSystemService(NotificationManager::class.java)
            .notify(debugNotificationId, buildNotification(appContext, reminder, isTest = true))
    }

    fun showUnlockedNotification(
        context: Context,
        goalId: Int,
        name: String,
        entryType: String,
    ) {
        val appContext = context.applicationContext
        createNotificationChannel(appContext)
        val now = Calendar.getInstance()
        val reminder = MotionGoalStartReminder(
            goalId = goalId,
            name = name,
            entryType = entryType,
            year = now.get(Calendar.YEAR),
            month = now.get(Calendar.MONTH) + 1,
            day = now.get(Calendar.DAY_OF_MONTH),
        )
        appContext.getSystemService(NotificationManager::class.java).notify(
            72000 + goalId,
            buildNotification(appContext, reminder, isUnlocked = true),
        )
    }

    private fun schedule(context: Context, reminder: MotionGoalStartReminder) {
        val triggerAt = triggerAtEpochMs(reminder)
        val now = System.currentTimeMillis()
        val startOfToday = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val reminderDay = Calendar.getInstance().apply {
            set(Calendar.YEAR, reminder.year)
            set(Calendar.MONTH, reminder.month - 1)
            set(Calendar.DAY_OF_MONTH, reminder.day)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

        if (reminderDay < startOfToday) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .putString(deliveredKey(reminder.goalId), reminder.signature)
                .apply()
            cancelAlarm(context, reminder.goalId)
            return
        }

        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val pendingIntent = alarmPendingIntent(context, reminder)
        val effectiveTrigger = if (triggerAt <= now) now + 1_500L else triggerAt
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    alarmManager.canScheduleExactAlarms() -> {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        effectiveTrigger,
                        pendingIntent,
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        effectiveTrigger,
                        pendingIntent,
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        effectiveTrigger,
                        pendingIntent,
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT -> {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        effectiveTrigger,
                        pendingIntent,
                    )
                }
                else -> {
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        effectiveTrigger,
                        pendingIntent,
                    )
                }
            }
        } catch (_: SecurityException) {
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                effectiveTrigger,
                pendingIntent,
            )
        }
    }

    private fun triggerAtEpochMs(reminder: MotionGoalStartReminder): Long {
        return Calendar.getInstance().apply {
            set(Calendar.YEAR, reminder.year)
            set(Calendar.MONTH, reminder.month - 1)
            set(Calendar.DAY_OF_MONTH, reminder.day)
            set(Calendar.HOUR_OF_DAY, reminderHour)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun alarmPendingIntent(
        context: Context,
        reminder: MotionGoalStartReminder,
    ): PendingIntent {
        val intent = Intent(context, MotionGoalReminderReceiver::class.java).apply {
            action = "com.motionllc.motion.goal.START_REMINDER"
            data = Uri.parse("motion://goal-start/${reminder.goalId}")
            putReminder(reminder)
        }
        return PendingIntent.getBroadcast(
            context,
            reminder.goalId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun cancelAlarm(context: Context, goalId: Int) {
        val intent = Intent(context, MotionGoalReminderReceiver::class.java).apply {
            action = "com.motionllc.motion.goal.START_REMINDER"
            data = Uri.parse("motion://goal-start/$goalId")
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            goalId,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        context.getSystemService(AlarmManager::class.java).cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun buildNotification(
        context: Context,
        reminder: MotionGoalStartReminder,
        isTest: Boolean = false,
        isUnlocked: Boolean = false,
    ): Notification {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val launchPendingIntent = PendingIntent.getActivity(
            context,
            reminder.goalId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val title = if (isTest) {
            "Goal reminder test"
        } else if (isUnlocked) {
            if (reminder.entryType == "goal") "Goal unlocked" else "Timeline unlocked"
        } else if (reminder.entryType == "goal") {
            "Goal starts today"
        } else {
            "Timeline starts today"
        }
        val detail = if (isTest) {
            reminder.name
        } else if (isUnlocked) {
            "${reminder.name} is now ready to begin."
        } else {
            "${reminder.name} is scheduled to begin today."
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, reminderChannelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
                .setPriority(Notification.PRIORITY_DEFAULT)
        }
        return builder
            .setSmallIcon(R.drawable.ic_motion_timer_notification)
            .setContentTitle(title)
            .setContentText(detail)
            .setStyle(Notification.BigTextStyle().bigText(detail))
            .setContentIntent(launchPendingIntent)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setColor(Color.rgb(0, 176, 240))
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .build()
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            reminderChannelId,
            "Goal and timeline reminders",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Reminds you when a scheduled Motion goal or timeline starts"
            enableVibration(true)
            setShowBadge(true)
        }
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun saveReminder(
        preferences: android.content.SharedPreferences,
        reminder: MotionGoalStartReminder,
    ) {
        preferences.edit()
            .putString(nameKey(reminder.goalId), reminder.name)
            .putString(typeKey(reminder.goalId), reminder.entryType)
            .putInt(yearKey(reminder.goalId), reminder.year)
            .putInt(monthKey(reminder.goalId), reminder.month)
            .putInt(dayKey(reminder.goalId), reminder.day)
            .apply()
    }

    private fun readReminder(
        preferences: android.content.SharedPreferences,
        goalId: Int,
    ): MotionGoalStartReminder? {
        val name = preferences.getString(nameKey(goalId), null) ?: return null
        val entryType = preferences.getString(typeKey(goalId), null) ?: return null
        val year = preferences.getInt(yearKey(goalId), 0)
        val month = preferences.getInt(monthKey(goalId), 0)
        val day = preferences.getInt(dayKey(goalId), 0)
        if (year <= 0 || month !in 1..12 || day !in 1..31) return null
        return MotionGoalStartReminder(goalId, name, entryType, year, month, day)
    }

    private fun clearReminder(
        preferences: android.content.SharedPreferences,
        goalId: Int,
    ) {
        preferences.edit()
            .remove(nameKey(goalId))
            .remove(typeKey(goalId))
            .remove(yearKey(goalId))
            .remove(monthKey(goalId))
            .remove(dayKey(goalId))
            .remove(deliveredKey(goalId))
            .apply()
    }

    private fun Intent.putReminder(reminder: MotionGoalStartReminder) {
        putExtra("goal_id", reminder.goalId)
        putExtra("goal_name", reminder.name)
        putExtra("entry_type", reminder.entryType)
        putExtra("start_year", reminder.year)
        putExtra("start_month", reminder.month)
        putExtra("start_day", reminder.day)
    }

    fun reminderFromIntent(intent: Intent): MotionGoalStartReminder? {
        val goalId = intent.getIntExtra("goal_id", -1)
        val name = intent.getStringExtra("goal_name").orEmpty()
        val entryType = intent.getStringExtra("entry_type").orEmpty()
        val year = intent.getIntExtra("start_year", 0)
        val month = intent.getIntExtra("start_month", 0)
        val day = intent.getIntExtra("start_day", 0)
        if (goalId < 0 || name.isBlank() || entryType.isBlank() ||
            year <= 0 || month !in 1..12 || day !in 1..31
        ) {
            return null
        }
        return MotionGoalStartReminder(goalId, name, entryType, year, month, day)
    }

    private fun notificationId(goalId: Int) = 62000 + goalId
    private fun nameKey(goalId: Int) = "name_$goalId"
    private fun typeKey(goalId: Int) = "type_$goalId"
    private fun yearKey(goalId: Int) = "year_$goalId"
    private fun monthKey(goalId: Int) = "month_$goalId"
    private fun dayKey(goalId: Int) = "day_$goalId"
    private fun deliveredKey(goalId: Int) = "delivered_$goalId"
}
