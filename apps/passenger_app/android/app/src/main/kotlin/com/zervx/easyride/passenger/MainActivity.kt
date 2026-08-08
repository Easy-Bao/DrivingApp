package com.zervx.easyride.passenger

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

private const val BACKGROUND_SERVICE_CLASS =
    "id.flutter.flutter_background_service.BackgroundService"
private const val BACKGROUND_SERVICE_PREFERENCES = "id.flutter.background_service"
private const val BACKGROUND_SERVICE_MANUALLY_STOPPED = "is_manually_stopped"
private const val TELEMETRY_NOTIFICATION_CHANNEL_ID = "easyride_passenger_location"

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        resetPersistedBackgroundService()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                TELEMETRY_NOTIFICATION_CHANNEL_ID,
                "Passenger location",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps location sharing active during an active ride."
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
        super.onCreate(savedInstanceState)
    }

    private fun resetPersistedBackgroundService() {
        getSharedPreferences(BACKGROUND_SERVICE_PREFERENCES, MODE_PRIVATE)
            .edit()
            .putBoolean(BACKGROUND_SERVICE_MANUALLY_STOPPED, true)
            .commit()
        stopService(Intent().setClassName(this, BACKGROUND_SERVICE_CLASS))
    }
}
