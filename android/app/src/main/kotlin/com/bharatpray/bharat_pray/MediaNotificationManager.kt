package com.bharatpray.bharat_pray

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import java.io.File

object MediaNotificationManager {
    private const val CHANNEL_ID = "bharat_pray_media_spotify_v8"
    private const val CHANNEL_NAME = "Sacred Bhajan Playback"
    private const val NOTIFICATION_ID = 108

    private var mediaSession: MediaSessionCompat? = null

    private fun getOrCreateMediaSession(context: Context): MediaSessionCompat {
        if (mediaSession == null) {
            mediaSession = MediaSessionCompat(context, "BharatPrayMediaSession").apply {
                setCallback(object : MediaSessionCompat.Callback() {
                    override fun onPlay() {
                        MainActivity.sendMediaActionToFlutter("action_resume")
                    }

                    override fun onPause() {
                        MainActivity.sendMediaActionToFlutter("action_pause")
                    }

                    override fun onSkipToNext() {
                        MainActivity.sendMediaActionToFlutter("action_next")
                    }

                    override fun onSkipToPrevious() {
                        MainActivity.sendMediaActionToFlutter("action_prev")
                    }

                    override fun onSeekTo(pos: Long) {
                        MainActivity.sendSeekToFlutter(pos)
                    }
                })
                isActive = true
            }
        }
        return mediaSession!!
    }

    fun showNotification(
        context: Context,
        title: String,
        subtitle: String,
        isPlaying: Boolean,
        imagePath: String?,
        durationSec: Int,
        positionSec: Int
    ) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Active Devotional Playback Controls"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        val session = getOrCreateMediaSession(context)

        val durationMs = durationSec.toLong() * 1000L
        val positionMs = positionSec.toLong() * 1000L

        // Decode Artwork Bitmap from imagePath
        var largeBitmap: Bitmap? = null
        if (!imagePath.isNullOrEmpty()) {
            val file = File(imagePath)
            if (file.exists()) {
                largeBitmap = BitmapFactory.decodeFile(file.absolutePath)
            }
        }
        if (largeBitmap == null) {
            largeBitmap = BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher)
        }

        // 1. Update MediaMetadata with duration and artwork for the OS Seekbar
        val metadataBuilder = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subtitle)
            .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, if (durationMs > 0) durationMs else -1L)
            .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, largeBitmap)
            .putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, largeBitmap)

        session.setMetadata(metadataBuilder.build())

        // 2. Update PlaybackState with interactive draggable seekbar actions
        val playbackActions = if (isPlaying) {
            PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_STOP or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
        } else {
            PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_SEEK_TO
        }

        val state = if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
        val playbackSpeed = if (isPlaying) 1.0f else 0.0f

        val stateBuilder = PlaybackStateCompat.Builder()
            .setActions(playbackActions)
            .setState(state, positionMs, playbackSpeed)

        session.setPlaybackState(stateBuilder.build())

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        // Action Intents
        val prevIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = MediaActionReceiver.ACTION_PREV
        }
        val prevPendingIntent = PendingIntent.getBroadcast(context, 101, prevIntent, flags)

        val playPauseIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = if (isPlaying) MediaActionReceiver.ACTION_PAUSE else MediaActionReceiver.ACTION_PLAY
        }
        val playPausePendingIntent = PendingIntent.getBroadcast(context, 102, playPauseIntent, flags)

        val nextIntent = Intent(context, MediaActionReceiver::class.java).apply {
            action = MediaActionReceiver.ACTION_NEXT
        }
        val nextPendingIntent = PendingIntent.getBroadcast(context, 103, nextIntent, flags)

        // Open App Intent
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("route", "bhajan_now_playing")
        }
        val openAppPendingIntent = PendingIntent.getActivity(context, 100, openAppIntent, flags)

        val playPauseIcon = if (isPlaying) R.drawable.ic_media_pause else R.drawable.ic_media_play

        // Sacred Saffron Orange theme color: #FF7700
        val themeOrange = Color.parseColor("#FF7700")

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_bharat_pray_logo)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setLargeIcon(largeBitmap)
            .setContentIntent(openAppPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setColor(themeOrange)
            .setColorized(true)
            .setOngoing(isPlaying)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(R.drawable.ic_media_prev, "Previous", prevPendingIntent)
            .addAction(playPauseIcon, if (isPlaying) "Pause" else "Play", playPausePendingIntent)
            .addAction(R.drawable.ic_media_next, "Next", nextPendingIntent)
            .setStyle(
                MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )

        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    fun cancelNotification(context: Context) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
        mediaSession?.let {
            it.isActive = false
            it.release()
            mediaSession = null
        }
    }
}
