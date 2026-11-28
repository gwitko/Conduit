package com.phyluke.conduit.adb

import android.os.Build
import io.github.muntashirakon.adb.AbsAdbConnectionManager
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.KeyPair
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.Certificate
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** libadb-android connection manager using the key from [AdbKeyStore]. */
class AdbManager(keys: AdbKeyStore) : AbsAdbConnectionManager() {

    private val pk: PrivateKey
    private val cert: Certificate

    init {
        setApi(Build.VERSION.SDK_INT)
        val kp = keys.loadKeyPair()
        pk = kp.private
        cert = buildSelfSignedCertificate(kp)
    }

    override fun getPrivateKey(): PrivateKey = pk
    override fun getCertificate(): Certificate = cert
    override fun getDeviceName(): String = "scrcpy-client"

    companion object {
        // DER encoding of AlgorithmIdentifier { sha256WithRSAEncryption, NULL }
        private val SHA256_RSA_ALG = tlv(0x30, byteArrayOf(
            0x06, 0x09, 0x2A, 0x86.toByte(), 0x48, 0x86.toByte(), 0xF7.toByte(), 0x0D, 0x01, 0x01, 0x0B,
            0x05, 0x00,
        ))

        /** Minimal self-signed X.509 certificate, hand-encoded as DER (no extra libraries). */
        fun buildSelfSignedCertificate(kp: KeyPair): Certificate {
            val name = tlv(0x30, tlv(0x31, tlv(0x30,
                byteArrayOf(0x06, 0x03, 0x55, 0x04, 0x03) + tlv(0x0C, "scrcpy-client".toByteArray()))))
            val fmt = SimpleDateFormat("yyMMddHHmmss'Z'", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
            val now = System.currentTimeMillis()
            val validity = tlv(0x30,
                tlv(0x17, fmt.format(Date(now - 86_400_000L)).toByteArray()) +
                tlv(0x17, fmt.format(Date(now + 3650L * 86_400_000L)).toByteArray()))
            val serial = tlv(0x02, BigInteger(63, SecureRandom()).add(BigInteger.ONE).toByteArray())
            val version = byteArrayOf(0xA0.toByte(), 0x03, 0x02, 0x01, 0x02)   // v3

            val tbs = tlv(0x30, version + serial + SHA256_RSA_ALG + name + validity + name + kp.public.encoded)

            val sig = Signature.getInstance("SHA256withRSA").run {
                initSign(kp.private); update(tbs); sign()
            }
            val der = tlv(0x30, tbs + SHA256_RSA_ALG + tlv(0x03, byteArrayOf(0x00) + sig))
            return CertificateFactory.getInstance("X.509").generateCertificate(ByteArrayInputStream(der))
        }

        private fun tlv(tag: Int, value: ByteArray): ByteArray {
            val out = ByteArrayOutputStream()
            out.write(tag)
            val n = value.size
            when {
                n < 128 -> out.write(n)
                n < 256 -> { out.write(0x81); out.write(n) }
                n < 65536 -> { out.write(0x82); out.write(n shr 8); out.write(n and 0xFF) }
                else -> { out.write(0x83); out.write(n shr 16); out.write((n shr 8) and 0xFF); out.write(n and 0xFF) }
            }
            out.write(value)
            return out.toByteArray()
        }
    }
}
