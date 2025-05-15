package com.example.demo_sound

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.IBinder
import android.util.Log
import androidx.annotation.Nullable

class RecorderService : android.app.Service() {
    override fun onCreate() {
        Log.e("onCreate", "onCreate")
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        Log.e("onStartCommand", "onStartCommand")
        val action: String? = intent.getAction()
        if ((action != null) && action == "stop") {
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }
        val serviceChannel: NotificationChannel = NotificationChannel(
            CHANNELID,
            "Foreground Service Channel",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        val manager: NotificationManager? = getSystemService<NotificationManager>(
            NotificationManager::class.java
        )
        if (manager != null) manager.createNotificationChannel(serviceChannel)

        val notification: Notification =
            Notification.Builder(this, CHANNELID).setContentTitle("Recorder Service").build()
        startForeground(1, notification)
        var samplerateString: String? = null
        var buffersizeString: String? = null
        val audioManager: AudioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (audioManager != null) {
            samplerateString = audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)
            buffersizeString =
                audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)
        }
        if (samplerateString == null) samplerateString = "48000"
        if (buffersizeString == null) buffersizeString = "480"
        val samplerate = samplerateString.toInt()
        val buffersize = buffersizeString.toInt()

        System.loadLibrary("RecorderExample") // Load native library.
        StartAudio(samplerate, buffersize, intent.getIntExtra("fileDescriptor", 0))
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        val data = StopRecording()
        val intent = Intent("com.sound.RECORDER_SERVICE")
        intent.putExtra("result", data)
        sendBroadcast(intent)
        Log.e("onDestroy", "onDestroy${data}")
    }

    @Nullable
    override fun onBind(intent: Intent): IBinder? {
        Log.e("onBind", "onBind")
        return null
    }

    private external fun StartAudio(samplerate: Int, buffersize: Int, destinationfd: Int)
    private external fun StopRecording(): Float
    companion object {
        const val CHANNELID: String = "RecorderServiceChannel"
    }
}
