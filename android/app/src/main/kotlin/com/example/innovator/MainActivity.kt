package com.innovation.innovator

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BACKGROUND_SERVICE_CHANNEL = "background_service"
    private val BATTERY_OPTIMIZATION_CHANNEL = "battery_optimization"
    private val NOTIFICATION_CHANNEL_ID = "high_importance_channel"
    private val FOREGROUND_SERVICE_CHANNEL_ID = "foreground_service_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannels()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_OPTIMIZATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> handleIsIgnoringBatteryOptimizations(result)
                "requestIgnoreBatteryOptimizations" -> handleRequestIgnoreBatteryOptimizations(result)
                "startForegroundService" -> handleStartForegroundService(result)
                "stopForegroundService" -> handleStopForegroundService(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleIsIgnoringBatteryOptimizations(result: MethodChannel.Result) {
        val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
        result.success(isIgnoring)
    }

    private fun handleRequestIgnoreBatteryOptimizations(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
        result.success(null)
    }

    private fun handleStartForegroundService(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, NotificationForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to start foreground service: ${e.message}", null)
        }
    }

    private fun handleStopForegroundService(result: MethodChannel.Result) {
        try {
            val serviceIntent = Intent(this, NotificationForegroundService::class.java)
            stopService(serviceIntent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to stop foreground service: ${e.message}", null)
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // High importance channel for notifications
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for important notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            // Foreground service channel
            val serviceChannel = NotificationChannel(
                FOREGROUND_SERVICE_CHANNEL_ID,
                "Background Service",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Channel for background service notifications"
                enableLights(false)
                enableVibration(false)
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            notificationManager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationClick(intent)
        
        // Start foreground service automatically when app starts
        handleStartForegroundService(object : MethodChannel.Result {
            override fun success(result: Any?) {}
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
            override fun notImplemented() {}
        })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationClick(intent)
    }

    private fun handleNotificationClick(intent: Intent?) {
        intent?.extras?.let { extras ->
            if (extras.getString("notification_click_action") == "FLUTTER_NOTIFICATION_CLICK") {
                // Handle notification click
            }
        }
    }
}

class NotificationForegroundService : Service() {
    private val FOREGROUND_SERVICE_CHANNEL_ID = "foreground_service_channel"
    private val NOTIFICATION_ID = 1001

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createForegroundNotification()
        return START_STICKY // This ensures the service restarts if killed
    }

    private fun createForegroundNotification() {
        val notification = NotificationCompat.Builder(this, FOREGROUND_SERVICE_CHANNEL_ID)
            .setContentTitle("Innovator")
            .setContentText("Keeping app alive for notifications")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
    }
    
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        // Restart the service if it gets destroyed
        val restartIntent = Intent(applicationContext, NotificationForegroundService::class.java)
        startService(restartIntent)
    }
}