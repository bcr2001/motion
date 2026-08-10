package com.motionllc.motion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MotionTimerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        MotionTimerService.handleScheduledTarget(
            context = context.applicationContext,
            timerStartedAtEpochMs = intent.getLongExtra(
                "timer_started_at_epoch_ms",
                0L,
            ),
        )
    }
}
