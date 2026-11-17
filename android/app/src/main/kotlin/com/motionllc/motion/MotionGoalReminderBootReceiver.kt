package com.motionllc.motion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MotionGoalReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        MotionGoalReminderScheduler.reschedulePersisted(context.applicationContext)
    }
}
