package com.gwitko.conduit

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import java.security.SecureRandom
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min

class FidoUsbCtapTransport(private val context: Context) {
    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val lock = Any()
    private var session: Session? = null
    private val random = SecureRandom()

    fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(true)
            "hasDevice" -> result.success(findCandidate() != null)
            "open" -> open(result)
            "close" -> {
                close()
                result.success(null)
            }
            "transceive" -> {
                val command = call.arguments as? ByteArray
                if (command == null) {
                    result.error("bad_arguments", "Expected a Uint8List CTAP command.", null)
                    return
                }
                Thread {
                    try {
                        val response = transceive(command)
                        result.success(response)
                    } catch (error: Throwable) {
                        result.error("usb_ctap", error.message ?: "USB security key failed.", null)
                    }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    fun open(result: MethodChannel.Result) {
        val candidate = findCandidate()
        if (candidate == null) {
            result.error("no_device", "No USB FIDO security key was found.", null)
            return
        }

        if (usbManager.hasPermission(candidate.device)) {
            Thread {
                try {
                    openCandidate(candidate)
                    result.success(null)
                } catch (error: Throwable) {
                    result.error("usb_open", error.message ?: "Could not open USB security key.", null)
                }
            }.start()
            return
        }

        requestPermission(candidate, result)
    }

    fun close() {
        synchronized(lock) {
            session?.close()
            session = null
        }
    }

    private fun requestPermission(candidate: Candidate, result: MethodChannel.Result) {
        val completed = AtomicBoolean(false)
        val action = "${context.packageName}.USB_PERMISSION"
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != action || !completed.compareAndSet(false, true)) return
                try {
                    context.unregisterReceiver(this)
                } catch (_: IllegalArgumentException) {
                }
                val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                if (!granted) {
                    result.error("permission_denied", "USB security key permission was denied.", null)
                    return
                }
                Thread {
                    try {
                        openCandidate(candidate)
                        result.success(null)
                    } catch (error: Throwable) {
                        result.error(
                            "usb_open",
                            error.message ?: "Could not open USB security key.",
                            null,
                        )
                    }
                }.start()
            }
        }

        val filter = IntentFilter(action)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            context.registerReceiver(receiver, filter)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
        val permissionIntent = PendingIntent.getBroadcast(
            context,
            USB_PERMISSION_REQUEST_CODE,
            Intent(action).setPackage(context.packageName),
            flags,
        )
        usbManager.requestPermission(candidate.device, permissionIntent)
    }

    private fun openCandidate(candidate: Candidate) {
        synchronized(lock) {
            session?.close()
            val connection = usbManager.openDevice(candidate.device)
                ?: throw IllegalStateException("Could not open USB security key.")
            if (!connection.claimInterface(candidate.usbInterface, true)) {
                connection.close()
                throw IllegalStateException("Could not claim USB security key interface.")
            }
            val opened = Session(
                connection = connection,
                usbInterface = candidate.usbInterface,
                input = candidate.input,
                output = candidate.output,
                packetSize = min(candidate.input.maxPacketSize, candidate.output.maxPacketSize)
                    .coerceAtLeast(MIN_PACKET_SIZE),
            )
            opened.cid = init(opened)
            session = opened
        }
    }

    private fun transceive(command: ByteArray): ByteArray {
        synchronized(lock) {
            val opened = session ?: throw IllegalStateException("USB security key is not open.")
            return cbor(opened, command)
        }
    }

    private fun init(session: Session): ByteArray {
        val nonce = ByteArray(8)
        random.nextBytes(nonce)
        val response = sendCommand(session, BROADCAST_CID, CTAPHID_INIT, nonce)
        if (response.cmd != CTAPHID_INIT || response.data.size < 17) {
            throw IllegalStateException("Invalid CTAP HID INIT response.")
        }
        for (i in nonce.indices) {
            if (response.data[i] != nonce[i]) {
                throw IllegalStateException("CTAP HID INIT nonce mismatch.")
            }
        }
        return response.data.copyOfRange(8, 12)
    }

    private fun cbor(session: Session, command: ByteArray): ByteArray {
        writeCommand(session, session.cid, CTAPHID_CBOR, command)
        while (true) {
            val response = readResponse(session, session.cid)
            when (response.cmd) {
                CTAPHID_CBOR -> return response.data
                CTAPHID_KEEPALIVE -> continue
                CTAPHID_ERROR -> {
                    val code = response.data.firstOrNull()?.toInt()?.and(0xff) ?: -1
                    throw IllegalStateException("Security key returned CTAP HID error $code.")
                }
                else -> throw IllegalStateException("Unexpected CTAP HID response ${response.cmd}.")
            }
        }
    }

    private fun sendCommand(
        session: Session,
        cid: ByteArray,
        command: Int,
        payload: ByteArray,
    ): HidResponse {
        writeCommand(session, cid, command, payload)
        return readResponse(session, cid)
    }

    private fun writeCommand(
        session: Session,
        cid: ByteArray,
        command: Int,
        payload: ByteArray,
    ) {
        val firstCapacity = session.packetSize - 7
        val continuationCapacity = session.packetSize - 5
        var offset = 0

        val first = ByteArray(session.packetSize)
        cid.copyInto(first, 0)
        first[4] = (command or 0x80).toByte()
        first[5] = ((payload.size ushr 8) and 0xff).toByte()
        first[6] = (payload.size and 0xff).toByte()
        val firstLength = min(firstCapacity, payload.size)
        payload.copyInto(first, 7, 0, firstLength)
        writePacket(session, first)
        offset += firstLength

        var sequence = 0
        while (offset < payload.size) {
            if (sequence > 0x7f) {
                throw IllegalStateException("CTAP HID payload is too large.")
            }
            val packet = ByteArray(session.packetSize)
            cid.copyInto(packet, 0)
            packet[4] = sequence.toByte()
            val chunkLength = min(continuationCapacity, payload.size - offset)
            payload.copyInto(packet, 5, offset, offset + chunkLength)
            writePacket(session, packet)
            offset += chunkLength
            sequence++
        }
    }

    private fun readResponse(session: Session, expectedCid: ByteArray): HidResponse {
        while (true) {
            val first = readPacket(session)
            if (!matchesCid(first, expectedCid)) continue

            val cmd = first[4].toInt() and 0xff
            if (cmd and 0x80 == 0) continue

            val length = ((first[5].toInt() and 0xff) shl 8) or
                (first[6].toInt() and 0xff)
            val data = ByteArray(length)
            val firstLength = min(length, session.packetSize - 7)
            first.copyInto(data, 0, 7, 7 + firstLength)
            var offset = firstLength
            var sequence = 0

            while (offset < length) {
                val packet = readPacket(session)
                if (!matchesCid(packet, expectedCid)) continue
                val receivedSequence = packet[4].toInt() and 0xff
                if (receivedSequence != sequence) {
                    throw IllegalStateException("Unexpected CTAP HID continuation sequence.")
                }
                val chunkLength = min(session.packetSize - 5, length - offset)
                packet.copyInto(data, offset, 5, 5 + chunkLength)
                offset += chunkLength
                sequence++
            }

            return HidResponse(cmd and 0x7f, data)
        }
    }

    private fun writePacket(session: Session, packet: ByteArray) {
        val written = session.connection.bulkTransfer(
            session.output,
            packet,
            packet.size,
            USB_TIMEOUT_MS,
        )
        if (written != packet.size) {
            throw IllegalStateException("Timed out writing to USB security key.")
        }
    }

    private fun readPacket(session: Session): ByteArray {
        val packet = ByteArray(session.packetSize)
        val read = session.connection.bulkTransfer(
            session.input,
            packet,
            packet.size,
            USB_TIMEOUT_MS,
        )
        if (read <= 0) {
            throw IllegalStateException("Timed out reading from USB security key.")
        }
        return if (read == packet.size) packet else packet.copyOf(read)
    }

    private fun matchesCid(packet: ByteArray, cid: ByteArray): Boolean {
        if (packet.size < 5) return false
        for (i in cid.indices) {
            if (packet[i] != cid[i]) return false
        }
        return true
    }

    private fun findCandidate(): Candidate? {
        for (device in usbManager.deviceList.values) {
            for (interfaceIndex in 0 until device.interfaceCount) {
                val usbInterface = device.getInterface(interfaceIndex)
                if (usbInterface.interfaceClass != UsbConstants.USB_CLASS_HID) continue

                var input: UsbEndpoint? = null
                var output: UsbEndpoint? = null
                for (endpointIndex in 0 until usbInterface.endpointCount) {
                    val endpoint = usbInterface.getEndpoint(endpointIndex)
                    if (endpoint.type != UsbConstants.USB_ENDPOINT_XFER_INT) continue
                    when (endpoint.direction) {
                        UsbConstants.USB_DIR_IN -> input = endpoint
                        UsbConstants.USB_DIR_OUT -> output = endpoint
                    }
                }

                if (input != null && output != null) {
                    return Candidate(device, usbInterface, input, output)
                }
            }
        }
        return null
    }

    private data class Candidate(
        val device: UsbDevice,
        val usbInterface: UsbInterface,
        val input: UsbEndpoint,
        val output: UsbEndpoint,
    )

    private data class HidResponse(val cmd: Int, val data: ByteArray)

    private class Session(
        val connection: UsbDeviceConnection,
        val usbInterface: UsbInterface,
        val input: UsbEndpoint,
        val output: UsbEndpoint,
        val packetSize: Int,
    ) {
        var cid: ByteArray = BROADCAST_CID

        fun close() {
            try {
                connection.releaseInterface(usbInterface)
            } finally {
                connection.close()
            }
        }
    }

    companion object {
        private const val USB_PERMISSION_REQUEST_CODE = 3001
        private const val USB_TIMEOUT_MS = 30000
        private const val MIN_PACKET_SIZE = 64
        private const val CTAPHID_INIT = 0x06
        private const val CTAPHID_CBOR = 0x10
        private const val CTAPHID_KEEPALIVE = 0x3b
        private const val CTAPHID_ERROR = 0x3f
        private val BROADCAST_CID = byteArrayOf(0xff.toByte(), 0xff.toByte(), 0xff.toByte(), 0xff.toByte())
    }
}
