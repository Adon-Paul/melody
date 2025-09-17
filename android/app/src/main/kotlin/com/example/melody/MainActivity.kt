package com.example.melody

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.media.app.NotificationCompat as MediaNotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "melody/notification"
    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "melody_music_channel"
    
    private lateinit var notificationManager: NotificationManager
    private var currentNotificationBuilder: NotificationCompat.Builder? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        NotificationActionReceiver.methodChannel = methodChannel
        
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    result.success(null)
                }
                "showMusicNotification" -> {
                    val title = call.argument<String>("title") ?: "Unknown Title"
                    val artist = call.argument<String>("artist") ?: "Unknown Artist"
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    showMusicNotification(title, artist, isPlaying)
                    result.success(null)
                }
                "updateNotification" -> {
                    val title = call.argument<String>("title")
                    val artist = call.argument<String>("artist")
                    val isPlaying = call.argument<Boolean>("isPlaying")
                    updateNotification(title, artist, isPlaying)
                    result.success(null)
                }
                "hideNotification" -> {
                    hideNotification()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Music Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Music playback controls"
                setShowBadge(false)
                setSound(null, null)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showMusicNotification(title: String, artist: String, isPlaying: Boolean) {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create notification actions
        val playPauseAction = NotificationCompat.Action.Builder(
            if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            if (isPlaying) "Pause" else "Play",
            createActionPendingIntent("PLAY_PAUSE")
        ).build()

        val previousAction = NotificationCompat.Action.Builder(
            android.R.drawable.ic_media_previous,
            "Previous",
            createActionPendingIntent("PREVIOUS")
        ).build()

        val nextAction = NotificationCompat.Action.Builder(
            android.R.drawable.ic_media_next,
            "Next",
            createActionPendingIntent("NEXT")
        ).build()

        currentNotificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(artist)
            .setContentIntent(pendingIntent)
            .setOngoing(isPlaying)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(previousAction)
            .addAction(playPauseAction)
            .addAction(nextAction)
            .setStyle(MediaNotificationCompat.MediaStyle()
                .setShowActionsInCompactView(0, 1, 2))

        notificationManager.notify(NOTIFICATION_ID, currentNotificationBuilder!!.build())
    }

    private fun updateNotification(title: String?, artist: String?, isPlaying: Boolean?) {
        currentNotificationBuilder?.let { builder ->
            title?.let { builder.setContentTitle(it) }
            artist?.let { builder.setContentText(it) }
            isPlaying?.let { 
                builder.setOngoing(it)
                // Update play/pause action
                builder.clearActions()
                
                val playPauseAction = NotificationCompat.Action.Builder(
                    if (it) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
                    if (it) "Pause" else "Play",
                    createActionPendingIntent("PLAY_PAUSE")
                ).build()

                val previousAction = NotificationCompat.Action.Builder(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    createActionPendingIntent("PREVIOUS")
                ).build()

                val nextAction = NotificationCompat.Action.Builder(
                    android.R.drawable.ic_media_next,
                    "Next",
                    createActionPendingIntent("NEXT")
                ).build()

                builder.addAction(previousAction)
                builder.addAction(playPauseAction)
                builder.addAction(nextAction)
            }
            notificationManager.notify(NOTIFICATION_ID, builder.build())
        }
    }

    private fun hideNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun createActionPendingIntent(action: String): PendingIntent {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            this, action.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
