package com.example.melody

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

class NotificationActionReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            "PLAY_PAUSE" -> {
                methodChannel?.invokeMethod("onPlayPause", null)
            }
            "NEXT" -> {
                methodChannel?.invokeMethod("onNext", null)
            }
            "PREVIOUS" -> {
                methodChannel?.invokeMethod("onPrevious", null)
            }
            "STOP" -> {
                methodChannel?.invokeMethod("onStop", null)
            }
        }
    }
}
