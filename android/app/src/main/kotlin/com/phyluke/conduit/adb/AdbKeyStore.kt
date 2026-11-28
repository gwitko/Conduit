package com.phyluke.conduit.adb

import android.content.Context
import android.util.Base64
import java.io.File
import java.math.BigInteger
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.interfaces.RSAPrivateCrtKey
import java.security.interfaces.RSAPublicKey
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.RSAPublicKeySpec

/**
 * Stores the RSA key used to authenticate to ADB targets.
 * Private key: PKCS#8 PEM in app-private storage (same format the official `adbkey` uses).
 * Public key (adbkey.pub format) is always derived from the private key.
 */
class AdbKeyStore(context: Context) {

    private val keyFile = File(context.filesDir, "adbkey")

    fun hasKey(): Boolean = keyFile.isFile

    /** Generates a key on first launch; no-op if one already exists. */
    fun ensureKey() {
        if (!hasKey()) generate()
    }

    fun generate() {
        val kp = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        writePrivate(kp.private.encoded)
    }

    /** Accepts a PKCS#8 PEM ("BEGIN PRIVATE KEY"), as produced by the official adb. */
    fun importPrivateKeyPem(pem: String) {
        require(!pem.contains("BEGIN RSA PRIVATE KEY")) {
            "Legacy PKCS#1 key format is not supported. Convert with: openssl pkcs8 -topk8 -nocrypt -in adbkey -out adbkey_pkcs8"
        }
        val der = pemToDer(pem)
        val key = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(der))
        require(key is RSAPrivateCrtKey) { "Not an RSA private key" }
        require(key.modulus.bitLength() in 2040..2048) { "ADB requires a 2048-bit RSA key" }
        writePrivate(der) // store only after validation
    }

    fun loadKeyPair(): KeyPair {
        val der = pemToDer(keyFile.readText())
        val priv = KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(der)) as RSAPrivateCrtKey
        val pub = KeyFactory.getInstance("RSA").generatePublic(RSAPublicKeySpec(priv.modulus, priv.publicExponent))
        return KeyPair(pub, priv)
    }

    fun privateKeyPem(): String = keyFile.readText()

    /** Contents of adbkey.pub: base64(struct) + " name\n". */
    fun publicKeyAdbFormat(comment: String = "scrcpy-client@android"): String {
        val pub = loadKeyPair().public as RSAPublicKey
        val b64 = Base64.encodeToString(encodeAdbPublicKey(pub), Base64.NO_WRAP)
        return "$b64 $comment\n"
    }

    /** Short fingerprint so you can compare keys visually. */
    fun fingerprint(): String {
        val pub = loadKeyPair().public as RSAPublicKey
        val md = MessageDigest.getInstance("SHA-256").digest(pub.modulus.toByteArray())
        return md.take(8).joinToString(":") { "%02x".format(it) }
    }

    private fun writePrivate(der: ByteArray) {
        val b64 = Base64.encodeToString(der, Base64.NO_WRAP).chunked(64).joinToString("\n")
        keyFile.writeText("-----BEGIN PRIVATE KEY-----\n$b64\n-----END PRIVATE KEY-----\n")
    }

    private fun pemToDer(pem: String): ByteArray {
        val body = pem.lines().filter { it.isNotBlank() && !it.startsWith("-----") }.joinToString("")
        return Base64.decode(body, Base64.DEFAULT)
    }

    companion object {
        private const val KEY_BYTES = 256 // 2048 bits
        private val TWO_32 = BigInteger.ONE.shiftLeft(32)

        /** Android's RSAPublicKey struct: len(words), n0inv, modulus LE, rr LE, exponent. */
        fun encodeAdbPublicKey(pub: RSAPublicKey): ByteArray {
            val n = pub.modulus
            val n0inv = n.mod(TWO_32).modInverse(TWO_32).negate().mod(TWO_32).toLong().toInt()
            val rr = BigInteger.ONE.shiftLeft(KEY_BYTES * 8 * 2).mod(n)
            return ByteBuffer.allocate(4 + 4 + KEY_BYTES + KEY_BYTES + 4)
                .order(ByteOrder.LITTLE_ENDIAN)
                .putInt(KEY_BYTES / 4)
                .putInt(n0inv)
                .put(toLittleEndian(n))
                .put(toLittleEndian(rr))
                .putInt(pub.publicExponent.toInt())
                .array()
        }

        private fun toLittleEndian(v: BigInteger): ByteArray {
            val be = v.toByteArray().let { if (it.size > KEY_BYTES) it.copyOfRange(it.size - KEY_BYTES, it.size) else it }
            val out = ByteArray(KEY_BYTES)
            for (i in be.indices) out[i] = be[be.size - 1 - i]
            return out
        }
    }
}
