package com.zervx.easyride.passenger

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

private const val TELEMETRY_NOTIFICATION_CHANNEL_ID = "easyride_passenger_location"

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
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
}
