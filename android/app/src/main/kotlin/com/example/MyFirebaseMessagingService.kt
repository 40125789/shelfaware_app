package com.example.shelfaware_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    // Handle incoming messages
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Check if the message contains a notification payload
        remoteMessage.notification?.let {
            // Handle notification
            sendNotification(it.title, it.body)
        }

        // Check if the message contains a data payload
        remoteMessage.data.isNotEmpty().let {
            // Handle data
            val foodItemId = remoteMessage.data["foodItemId"]
            val expiryDate = remoteMessage.data["expiryDate"]
            // You can perform further actions like opening an activity or storing the data
        }
    }

    // Handle new FCM token
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Send the new token to your server if needed
        sendTokenToServer(token)
    }

    private fun sendNotification(title: String?, body: String?) {
        val notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Notification channel ID (required for Android 8.0+)
        val channelId = "default"

        // Create a notification builder
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title) // Notification title
            .setContentText(body)   // Notification body
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Set a small icon for the notification
            .setAutoCancel(true)  // Auto-dismiss the notification when clicked
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)  // Set the priority

        // Check if the Android version is 8.0 or higher to handle notification channels
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Default Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Channel for general notifications"
            }

            // Register the channel with the system
            notificationManager.createNotificationChannel(channel)
        }

        // Issue the notification
        notificationManager.notify(0, notificationBuilder.build())
    }

    private fun sendTokenToServer(token: String) {
        // Send the new token to your server to associate it with the user's account
        // Example: Send the token to your backend or Firestore
    }
}
