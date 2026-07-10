package com.gwitko.conduit

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.IBinder
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private lateinit var fidoUsbCtapTransport: FidoUsbCtapTransport

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fidoUsbCtapTransport = FidoUsbCtapTransport(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKGROUND_KEEPALIVE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val sessionCount = call.argument<Int>("sessionCount") ?: 0
                    BackgroundConnectionService.start(this, sessionCount)
                    result.success(null)
                }
                "stop" -> {
                    BackgroundConnectionService.stop(this)
                    result.success(null)
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermissionIfNeeded()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FIDO_USB_CHANNEL,
        ).setMethodCallHandler { call, result ->
            fidoUsbCtapTransport.handle(call, result)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LOCAL_SHELL_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "environment" -> result.success(
                    mapOf(
                        "nativeLibraryDir" to applicationInfo.nativeLibraryDir,
                        "filesDir" to filesDir.absolutePath,
                        "sharedStorageFeatureEnabled" to BuildConfig.FULL_STORAGE_ACCESS,
                        "sharedStorageDir" to sharedStorageDir(),
                        "sharedStorageAccessGranted" to hasSharedStorageAccess(),
                        "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
                    ),
                )
                "requestSharedStorageAccess" -> {
                    requestSharedStorageAccess()
                    result.success(hasSharedStorageAccess())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasSharedStorageAccess(): Boolean {
        if (!BuildConfig.FULL_STORAGE_ACCESS) return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestSharedStorageAccess() {
        if (!BuildConfig.FULL_STORAGE_ACCESS) return
        if (hasSharedStorageAccess()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:$packageName"),
            )
            startActivity(intent)
        } else {
            requestPermissions(
                arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                SHARED_STORAGE_PERMISSION_REQUEST_CODE,
            )
        }
    }

    private fun sharedStorageDir(): String {
        if (!BuildConfig.FULL_STORAGE_ACCESS) return ""
        return Environment.getExternalStorageDirectory().absolutePath
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) return
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    companion object {
        const val BACKGROUND_KEEPALIVE_CHANNEL = "conduit/background_keepalive"
        const val FIDO_USB_CHANNEL = "conduit/fido_usb"
        const val LOCAL_SHELL_CHANNEL = "conduit/local_shell"
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 2001
        private const val SHARED_STORAGE_PERMISSION_REQUEST_CODE = 2002
    }
}

class BackgroundConnectionService : Service() {
    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val sessionCount = intent?.getIntExtra(SESSION_COUNT_EXTRA, 0) ?: 0
        val notification = buildNotification(sessionCount)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active sessions",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps active sessions running while Conduit is in the background."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(sessionCount: Int): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val sessionLabel = if (sessionCount == 1) "session" else "sessions"

        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Conduit")
            .setContentText("$sessionCount active $sessionLabel")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "ssh_sessions"
        private const val NOTIFICATION_ID = 1001
        private const val SESSION_COUNT_EXTRA = "session_count"

        fun start(context: Context, sessionCount: Int) {
            val intent = Intent(context, BackgroundConnectionService::class.java).apply {
                putExtra(SESSION_COUNT_EXTRA, sessionCount)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BackgroundConnectionService::class.java))
        }
    }
}
