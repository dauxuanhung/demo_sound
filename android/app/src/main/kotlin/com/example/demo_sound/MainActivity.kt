package com.example.demo_sound


import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sound.channel"
    private var recording = false
    private var recordingFile: File? = null
    private var pendingResult: MethodChannel.Result? = null

    private external fun GetBmpFromFile(path: String): Float
    private external fun NativeInit(samplerate: Int, buffersize: Int, tempPath: String)


    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val result = intent?.getFloatExtra("result", 0f) ?: 0f
            Log.e("onReceive", result.toString());
            pendingResult?.success(result)
            pendingResult = null
        }
    }


    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(receiver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val filter = IntentFilter("com.sound.RECORDER_SERVICE")
        ContextCompat.registerReceiver(this, receiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        recordingFile = File(filesDir.absolutePath, "recording.wav")
        System.loadLibrary("RecorderExample")
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "startRecorder") {
                val nativeResponse = startRecorder()
                result.success(nativeResponse)
            } else if (call.method == "stopRecorder") {
                stopService()
                result.success(recordingFile?.absolutePath)
            } else if (call.method == "getBmp") {
                pendingResult = result
            } else if (call.method == "getBmpOfFile") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    val bmp = GetBmpFromFile(filePath)
                    result.success(bmp)
                }
                println("Received from Flutter: $filePath")
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startRecorder(): String {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO
        )
        for (s in permissions) {
            if (ContextCompat.checkSelfPermission(this, s) !== PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, permissions, 0)
                return "Please allow all permissions for the app."
            }
        }
        startService()
        return "Hello from Android Native!"
    }


    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String?>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if ((requestCode != 0) || (grantResults.size < 1) || (grantResults.size != permissions.size)) return
        var hasAllPermissions = true

        for (grantResult in grantResults) if (grantResult != PackageManager.PERMISSION_GRANTED) {
            hasAllPermissions = false
            Toast.makeText(
                applicationContext,
                "Please allow all permissions for the app.",
                Toast.LENGTH_LONG
            ).show()
        }
        if (hasAllPermissions) {

        }
    }

    private fun startService() {
        try {
            val pfd = contentResolver.openFileDescriptor(
                Uri.fromFile(
                    recordingFile
                ), "w"
            )
            val serviceIntent = Intent(this@MainActivity, RecorderService::class.java)
            serviceIntent.putExtra("fileDescriptor", pfd!!.detachFd())
            ContextCompat.startForegroundService(this, serviceIntent)
            recording = true
        } catch (e: FileNotFoundException) {
            e.printStackTrace()
        }
    }


    private fun stopService() {
        if (recording) {
            val serviceIntent = Intent(this, RecorderService::class.java)
            serviceIntent.setAction("stop")
            startService(serviceIntent)
            recording = false
        }
    }
}
