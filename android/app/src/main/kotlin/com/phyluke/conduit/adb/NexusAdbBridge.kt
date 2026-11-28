package com.phyluke.conduit.adb

import android.content.Context
import android.os.Handler
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.concurrent.Executors

class NexusAdbBridge(private val context: Context) {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(context.mainLooper)
    private val keyStore = AdbKeyStore(context)

    @Volatile
    private var manager: AdbManager? = null

    fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ensureKey" -> runAsync(result) {
                keyStore.ensureKey()
                mapOf(
                    "hasKey" to keyStore.hasKey(),
                    "fingerprint" to keyStore.fingerprint(),
                )
            }
            "publicKey" -> runAsync(result) {
                keyStore.ensureKey()
                keyStore.publicKeyAdbFormat("nexus@conduit")
            }
            "connect" -> {
                val host = call.argument<String>("host")?.trim().orEmpty()
                val port = call.argument<Int>("port") ?: 5555
                if (host.isEmpty()) {
                    result.error("bad_arguments", "Host is required.", null)
                    return
                }
                runAsync(result) {
                    keyStore.ensureKey()
                    val nextManager = AdbManager(keyStore)
                    val connected = nextManager.connect(host, port)
                    if (!connected) {
                        throw IllegalStateException("Failed to connect to $host:$port")
                    }
                    manager?.close()
                    manager = nextManager
                    mapOf(
                        "connected" to true,
                        "host" to host,
                        "port" to port,
                    )
                }
            }
            "shell" -> {
                val command = call.argument<String>("command")?.trim().orEmpty()
                if (command.isEmpty()) {
                    result.error("bad_arguments", "Command is required.", null)
                    return
                }
                runAsync(result) {
                    val active = manager ?: throw IllegalStateException("Not connected to an ADB target.")
                    val stream = active.openStream("shell:$command")
                    stream.use { s ->
                        BufferedReader(InputStreamReader(s.openInputStream())).use { reader ->
                            reader.readText()
                        }
                    }
                }
            }
            "disconnect" -> runAsync(result) {
                manager?.close()
                manager = null
                true
            }
            else -> result.notImplemented()
        }
    }

    private fun <T> runAsync(result: MethodChannel.Result, block: () -> T) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post {
                    result.success(value)
                }
            } catch (error: Throwable) {
                mainHandler.post {
                    result.error("adb_error", error.message ?: "ADB operation failed.", null)
                }
            }
        }
    }
}