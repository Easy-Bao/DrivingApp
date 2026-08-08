package com.zervx.easyride.driver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

private const val TELEMETRY_NOTIFICATION_CHANNEL_ID = "easyride_driver_location"

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
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
}
