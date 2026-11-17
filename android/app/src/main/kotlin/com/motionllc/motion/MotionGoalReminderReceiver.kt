package com.motionllc.motion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MotionGoalReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val reminder = MotionGoalReminderScheduler.reminderFromIntent(intent) ?: return
        MotionGoalReminderScheduler.deliver(context.applicationContext, reminder)
    }
}
