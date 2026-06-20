package com.motionllc.motion

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import kotlin.math.roundToInt

class MotionAnalyticsWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildRemoteViews(context))
        }
    }

    companion object {
        private const val preferencesName = "motion_home_widget"
        private const val todayXpKey = "today_xp"
        private const val targetXpKey = "target_xp"
        private const val currentStreakKey = "current_streak"
        private const val badgeLevelKey = "badge_level"
        private const val badgeNameKey = "badge_name"
        private const val progressKey = "progress"

        fun saveAndRefresh(
            context: Context,
            todayXp: Int,
            targetXp: Int,
            currentStreak: Int,
            badgeLevel: String,
            badgeName: String,
            progress: Double,
        ) {
            context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .putInt(todayXpKey, todayXp)
                .putInt(targetXpKey, targetXp)
                .putInt(currentStreakKey, currentStreak)
                .putString(badgeLevelKey, badgeLevel)
                .putString(badgeNameKey, badgeName)
                .putFloat(progressKey, progress.toFloat())
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, MotionAnalyticsWidget::class.java)
            manager.getAppWidgetIds(component).forEach { widgetId ->
                manager.updateAppWidget(widgetId, buildRemoteViews(context))
            }
        }

        private fun buildRemoteViews(context: Context): RemoteViews {
            val preferences =
                context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val todayXp = preferences.getInt(todayXpKey, 0)
            val targetXp = preferences.getInt(targetXpKey, 0)
            val currentStreak = preferences.getInt(currentStreakKey, 0)
            val badgeLevel = preferences.getString(badgeLevelKey, "timeNovice").orEmpty()
            val badgeName = preferences.getString(badgeNameKey, "Time Novice").orEmpty()
            val progress = preferences.getFloat(progressKey, 0f).coerceIn(0f, 1f)

            val views = RemoteViews(context.packageName, R.layout.motion_analytics_widget)
            views.setTextViewText(R.id.widget_xp_value, "$todayXp / $targetXp XP")
            views.setTextViewText(R.id.widget_badge_name, badgeName)
            views.setTextViewText(
                R.id.widget_streak_value,
                if (currentStreak == 1) "1 day" else "$currentStreak days",
            )
            views.setProgressBar(
                R.id.widget_progress,
                100,
                (progress * 100).roundToInt(),
                false,
            )
            views.setImageViewResource(R.id.widget_badge_image, badgeDrawable(badgeLevel))

            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            return views
        }

        private fun badgeDrawable(level: String): Int {
            return when (level) {
                "focusedBeginner" -> R.drawable.motion_badge_dolphin
                "timePro" -> R.drawable.motion_badge_eagle
                "timeMaster" -> R.drawable.motion_badge_dragon
                "timeWizard" -> R.drawable.motion_badge_wizard
                else -> R.drawable.motion_badge_sloth
            }
        }
    }
}
