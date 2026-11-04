package com.bharatpray.bharat_pray

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MediaActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_PLAY = "com.bharatpray.ACTION_PLAY"
        const val ACTION_PAUSE = "com.bharatpray.ACTION_PAUSE"
        const val ACTION_PLAY_PAUSE = "com.bharatpray.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.bharatpray.ACTION_NEXT"
        const val ACTION_PREV = "com.bharatpray.ACTION_PREV"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = when (intent.action) {
            ACTION_PLAY -> "action_resume"
            ACTION_PAUSE -> "action_pause"
            ACTION_PLAY_PAUSE -> "action_play_pause"
            ACTION_NEXT -> "action_next"
            ACTION_PREV -> "action_prev"
            else -> intent.getStringExtra("action")
        } ?: return

        MainActivity.sendMediaActionToFlutter(action)
    }
}
