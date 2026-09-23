package com.zervx.easyride.driver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.ToneGenerator
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val BACKGROUND_SERVICE_CLASS =
    "id.flutter.flutter_background_service.BackgroundService"
private const val BACKGROUND_SERVICE_PREFERENCES = "id.flutter.background_service"
private const val BACKGROUND_SERVICE_MANUALLY_STOPPED = "is_manually_stopped"
private const val TELEMETRY_NOTIFICATION_CHANNEL_ID = "easyride_driver_location"
private const val DRIVER_ALERT_CHANNEL = "easyride/driver_alerts"
private const val PLAY_INCOMING_RIDE_ALERT = "playIncomingRideAlert"

class MainActivity : FlutterActivity() {
    private var incomingRideTone: ToneGenerator? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        resetPersistedBackgroundService()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                TELEMETRY_NOTIFICATION_CHANNEL_ID,
                "Driver location",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps location sharing active while you are online."
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DRIVER_ALERT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                PLAY_INCOMING_RIDE_ALERT -> {
                    playIncomingRideAlert()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playIncomingRideAlert() {
        incomingRideTone?.release()
        incomingRideTone = ToneGenerator(android.media.AudioManager.STREAM_ALARM, 100)
        incomingRideTone?.startTone(ToneGenerator.TONE_PROP_BEEP2, 800)
    }

    override fun onDestroy() {
        incomingRideTone?.release()
        incomingRideTone = null
        super.onDestroy()
    }

    private fun resetPersistedBackgroundService() {
        // The service can outlive a hot reinstall with a callback from an old
        // package. Mark it stopped before destroying it so its watchdog cannot
        // restart the stale isolate while the new Flutter engine boots.
        getSharedPreferences(BACKGROUND_SERVICE_PREFERENCES, MODE_PRIVATE)
            .edit()
            .putBoolean(BACKGROUND_SERVICE_MANUALLY_STOPPED, true)
            .commit()
        stopService(Intent().setClassName(this, BACKGROUND_SERVICE_CLASS))
    }
}
